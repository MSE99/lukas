defmodule LukasWeb.Operator.InvitesLive do
  use LukasWeb, :live_view

  alias Lukas.Accounts
  alias Phoenix.LiveView.AsyncResult

  def mount(_, _, socket) do
    Accounts.watch_invites()

    next_socket =
      socket
      |> assign(:loading_result, AsyncResult.loading())
      |> start_async(:loading, fn -> Accounts.list_invites() end)

    {:ok, next_socket}
  end

  def handle_async(:loading, {:ok, invites}, socket) do
    Accounts.watch_invites()

    next_socket =
      socket
      |> stream(:invites, invites)
      |> assign(:loading_result, AsyncResult.ok(socket.assigns.loading_result, nil))

    {:noreply, next_socket}
  end

  def handle_async(:loading, {:exit, reason}, socket) do
    {:noreply,
     assign(socket, loading_result: AsyncResult.failed(socket.assigns.loading_result, reason))}
  end

  def render(assigns) do
    ~H"""
    <h1>Invites</h1>

    <.async_result assign={@loading_result}>
      <:loading>Loading...</:loading>
      <:failed>Failed to load invites...</:failed>

      <.button id="generate-lecturer-invite-button" phx-click="generate-lecturer-invite">
        Generate lecturer invite
      </.button>

      <.button id="generate-operator-invite-button" phx-click="generate-operator-invite">
        Generate operator invite
      </.button>

      <ul id="invites" phx-update="stream">
        <li :for={{id, inv} <- @streams.invites} id={id}>
          <%= inv.code %> | <%= inv.kind %>
          <.button class="delete-invite-button" phx-value-id={inv.id} phx-click="delete-invite">
            Delete invite
          </.button>
        </li>
      </ul>
    </.async_result>
    """
  end

  def handle_event("delete-invite", %{"id" => raw_id}, socket) do
    {id, _} = Integer.parse(raw_id)
    Accounts.delete_invite!(id)
    {:noreply, socket}
  end

  def handle_event("generate-lecturer-invite", _, socket) do
    Accounts.generate_lecturer_invite!()
    {:noreply, socket}
  end

  def handle_event("generate-operator-invite", _, socket) do
    Accounts.generate_operator_invite!()
    {:noreply, socket}
  end

  def handle_info({:invites, :invite_created, inv}, socket) do
    {:noreply, stream_insert(socket, :invites, inv)}
  end

  def handle_info({:invites, :invite_deleted, inv}, socket) do
    {:noreply, stream_delete(socket, :invites, inv)}
  end
end
