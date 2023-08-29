defmodule LukasWeb.Operator.InvitesLive do
  use LukasWeb, :live_view

  alias Lukas.Accounts

  def mount(_, _, socket) do
    Accounts.watch_invites()

    invites = Accounts.list_invites()
    {:ok, stream(socket, :invites, invites)}
  end

  def render(assigns) do
    ~H"""
    <h1>Invites</h1>

    <.button id="generate-invite-button" phx-click="generate-invite">Generate invite</.button>

    <ul id="invites" phx-update="stream">
      <li :for={{id, inv} <- @streams.invites} id={id}>
        <%= inv.code %>
        <.button class="delete-invite-button" phx-value-id={inv.id} phx-click="delete-invite">
          Delete invite
        </.button>
      </li>
    </ul>
    """
  end

  def handle_event("delete-invite", %{"id" => raw_id}, socket) do
    {id, _} = Integer.parse(raw_id)
    Accounts.delete_invite!(id)
    {:noreply, socket}
  end

  def handle_event("generate-invite", _, socket) do
    Accounts.generate_invite!()
    {:noreply, socket}
  end

  def handle_info({:invites, :invite_created, inv}, socket) do
    {:noreply, stream_insert(socket, :invites, inv)}
  end

  def handle_info({:invites, :invite_deleted, inv}, socket) do
    {:noreply, stream_delete(socket, :invites, inv)}
  end
end
