defmodule LukasWeb.Students.WalletLive do
  use LukasWeb, :live_view

  alias Lukas.Money
  alias Phoenix.LiveView.AsyncResult

  def mount(_, _, socket) do
    next_socket =
      socket
      |> stream_configure(:transactions, dom_id: &Money.tag_from_tx/1)
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
    <ul class="flex gap-1 text-lg text-secondary my-8">
      <li>
        <.link navigate={~p"/home"}>home</.link>
      </li>
      <li>
        /
      </li>
      <li>
        <.link navigate={~p"/home/wallet"}>wallet</.link>
      </li>
    </ul>

    <.async_result assign={@loading}>
      <:loading>Loading...</:loading>
      <:failed>Failed to load wallet</:failed>

      <div class="text-secondary flex flex-col justify-center items-center mb-10">
        <.icon name="hero-wallet-solid" class="w-[140px] h-[140px]" />
        <p><%= @wallet_amount |> format_amount() %> LYD</p>
      </div>

      <ul id="txs" phx-update="stream">
        <li :for={{id, tx} <- @streams.transactions} id={id} class="m-3 flex items-center gap-2">
          <.icon
            name="hero-currency-dollar-solid"
            class={["w-8 h-8", if(Money.is_deposit(tx), do: "text-primary", else: "text-red-500")]}
          />
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
end
