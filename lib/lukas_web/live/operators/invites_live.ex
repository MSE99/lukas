defmodule LukasWeb.Operator.InvitesLive do
  use LukasWeb, :live_view

  alias Lukas.Accounts
  alias LukasWeb.CommonComponents
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
    <CommonComponents.navigate_breadcrumbs links={[
      {~p"/controls", gettext("home")},
      {~p"/controls/invites", gettext("invites")}
    ]} />

    <.async_result assign={@loading_result}>
      <:loading>
        <.loading_spinner />
      </:loading>

      <:failed>Failed to load invites...</:failed>

      <div class="flex justify-center md:justify-end gap-2 mb-10">
        <.button id="generate-lecturer-invite-button" phx-click="generate-lecturer-invite">
          <%= gettext("Create lecturer invite") %>
        </.button>

        <.button id="generate-operator-invite-button" phx-click="generate-operator-invite">
          <%= gettext("Create operator invite") %>
        </.button>
      </div>

      <div class="text-secondary font-bold gap-2 mb-5">
        <span class="me-4">
          <%= gettext("Code") %>
        </span>
        <span>
          <%= gettext("Kind") %>
        </span>
      </div>

      <ul id="invites" phx-update="stream">
        <li
          :for={{id, inv} <- @streams.invites}
          id={id}
          class="flex items-center gap-2 mb-5 border-b pb-2"
        >
          <span><%= inv.code %></span>
          <span><%= invite_kind_to_string(inv.kind) %></span>

          <div
            class="delete-invite-button ms-auto hover:cursor-pointer"
            phx-value-id={inv.id}
            phx-click="delete-invite"
          >
            <.icon name="hero-x-mark" />
          </div>
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

  def invite_kind_to_string(:lecturer), do: gettext("lecturer")
  def invite_kind_to_string(:operator), do: gettext("operator")
end
