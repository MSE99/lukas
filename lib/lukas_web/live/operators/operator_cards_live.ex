defmodule LukasWeb.Operator.CardsLive do
  use LukasWeb, :live_view

  alias Lukas.Money
  alias LukasWeb.CommonComponents
  alias Phoenix.LiveView.AsyncResult

  def mount(_, _, socket) do
    next_socket =
      socket
      |> assign(:loading_result, AsyncResult.loading())
      |> start_async(:loading, fn -> Money.list_top_up_cards() end)

    {:ok, next_socket}
  end

  def handle_async(:loading, {:ok, cards}, socket) do
    next_socket =
      socket
      |> stream(:cards, cards)
      |> assign(:loading_result, AsyncResult.ok(socket.assigns.loading_result, nil))

    {:noreply, next_socket}
  end

  def handle_async(:loading, {:exit, reason}, socket) do
    {:noreply,
     assign(socket, loading_result: AsyncResult.failed(socket.assigns.loading_result, reason))}
  end

  def render(assigns) do
    ~H"""
    <CommonComponents.navigate_breadcrumbs links={[
      {~p"/controls", gettext("home")},
      {~p"/controls/cards", gettext("cards")}
    ]} />

    <.async_result assign={@loading_result}>
      <:loading>
        <.loading_spinner />
      </:loading>

      <:failed>Failed to load cards...</:failed>

      <div class="flex justify-center md:justify-end gap-2 mb-10">
        <.button id="generate-operator-invite-button" phx-click={show_modal(%JS{}, "add-modal")}>
          <%= gettext("Generate new card") %>
        </.button>
      </div>

      <div class="text-secondary font-bold gap-2 mb-5">
        <span class="me-4">
          <%= gettext("Code") %>
        </span>
        <span>
          <%= gettext("Value") %>
        </span>
      </div>

      <ul id="cards" phx-update="stream">
        <li
          :for={{id, inv} <- @streams.cards}
          id={id}
          class="flex items-center gap-2 mb-5 border-b pb-2"
        >
          <span><%= inv.code %></span>
          <span><%= inv.value %></span>

          <div
            class="delete-invite-button ms-auto hover:cursor-pointer"
            phx-value-id={inv.id}
            phx-click="delete"
          >
            <.icon name="hero-x-mark" />
          </div>
        </li>
      </ul>

      <.modal id="add-modal">
        <form phx-submit={JS.push("generate") |> hide_modal("add-modal")}>
          <input type="number" name="value" required min={0} />

          <.button id="generate-operator-invite-button" phx-disable-width="generating...">
            <%= gettext("Generate") %>
          </.button>
        </form>
      </.modal>
    </.async_result>
    """
  end

  def handle_event("generate", %{"value" => raw_value}, socket) do
    {:ok, card} = Money.generate_top_up_card(String.to_integer(raw_value))
    {:noreply, stream_insert(socket, :cards, card)}
  end

  def handle_event("delete", %{"id" => raw_id}, socket) do
    {:ok, card} =
      raw_id
      |> String.to_integer()
      |> Money.delete_card()

    {:noreply, stream_delete(socket, :cards, card)}
  end
end
