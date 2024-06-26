defmodule LukasWeb.Students.WalletLive do
  use LukasWeb, :live_view

  alias Lukas.Money
  alias Phoenix.LiveView.AsyncResult
  alias LukasWeb.CommonComponents

  def mount(_, _, socket) do
    next_socket =
      socket
      |> stream_configure(:transactions, dom_id: &Money.tag_from_tx/1)
      |> assign(:error, "")
      |> assign(:loading, AsyncResult.loading())
      |> start_async(:loading, fn ->
        {Money.list_transactions!(socket.assigns.current_user),
         Money.get_deposited_amount!(socket.assigns.current_user)}
      end)

    {:ok, next_socket}
  end

  def handle_async(:loading, {:ok, {txs, wallet_amount}}, socket) do
    Money.watch_wallet(socket.assigns.current_user)

    {:noreply,
     socket
     |> stream(:transactions, txs)
     |> assign(:wallet_amount, wallet_amount)
     |> assign(:loading, AsyncResult.ok(socket.assigns.loading, nil))}
  end

  def handle_async(:loading, {:exit, reason}, socket) do
    {:noreply,
     socket
     |> assign(:loading, AsyncResult.failed(socket.assigns.loading, reason))}
  end

  def render(assigns) do
    ~H"""
    <CommonComponents.navigate_breadcrumbs links={[
      {~p"/home", gettext("home")},
      {~p"/home/wallet", gettext("wallet")}
    ]} />

    <.async_result assign={@loading}>
      <:loading>
        <.loading_spinner />
      </:loading>
      <:failed>Failed to load wallet</:failed>

      <form id="top-up-card" phx-submit="use-card">
        <.input type="text" name="code" value="" label={gettext("Code")} required />
        <.button class="mt-5">
          <%= gettext("Charge") %>
        </.button>

        <.error :if={@error != ""}>
          <%= @error %>
        </.error>
      </form>

      <div class="text-secondary flex flex-col justify-center items-center mb-10">
        <.icon name="hero-wallet-solid" class="w-[140px] h-[140px]" />
        <p><%= @wallet_amount |> format_amount() %> LYD</p>
      </div>

      <ul id="txs" phx-update="stream" class="list-disc pl-3 text-secondary">
        <li :for={{id, tx} <- @streams.transactions} id={id} class="flex items-center pb-2 border-b">
          <%= Money.describe_tx(tx) %>
        </li>
      </ul>
    </.async_result>
    """
  end

  defp format_amount(amount), do: :erlang.float_to_binary(amount, decimals: 1)

  def handle_info({:wallet, _, :amount_updated, next_amount}, socket) do
    {:noreply, assign(socket, wallet_amount: next_amount)}
  end

  def handle_event("use-card", %{"code" => code}, socket) do
    case Money.use_top_up_card(socket.assigns.current_user, code) do
      :ok ->
        {:noreply,
         assign(socket, error: "")
         |> push_navigate(to: ~p"/home/wallet")}

      {:error, reason} ->
        {:noreply, assign(socket, error: reason)}
    end
  end
end
