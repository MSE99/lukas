defmodule LukasWeb.Operator.LecturersLive do
  use LukasWeb, :live_view

  alias Lukas.Accounts
  alias LukasWeb.CommonComponents

  def mount(_, _, socket) do
    if connected?(socket) do
      Accounts.watch_lecturers()
    end

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <CommonComponents.navigate_breadcrumbs links={[
      {~p"/controls", "home"},
      {~p"/controls/lecturers", "lecturers"}
    ]} />

    <.live_component
      module={LukasWeb.PagedList}
      id="lecturers-list"
      page={1}
      limit={50}
      load={fn opts -> Accounts.list_lecturers(opts) end}
      entry_dom_id={fn lect -> "lecturers-#{lect.id}" end}
    >
      <:item :let={lect}>
        <CommonComponents.user_record user={lect}>
          <:links :let={lect}>
            <.link
              navigate={~p"/controls/lecturers/#{lect.id}"}
              class="mr-auto text-secondary hover:underline"
            >
              <%= lect.name %>
            </.link>
          </:links>

          <:action :let={lect}>
            <.button
              :if={lect.enabled}
              id={"lecturer-#{lect.id}-disable"}
              phx-click="disable-lecturer"
              phx-value-id={lect.id}
            >
              Disable
            </.button>

            <.button
              :if={!lect.enabled}
              id={"lecturer-#{lect.id}-enable"}
              phx-click="enable-lecturer"
              phx-value-id={lect.id}
            >
              Enable
            </.button>
          </:action>
        </CommonComponents.user_record>
      </:item>
    </.live_component>
    """
  end

  def handle_event("disable-lecturer", %{"id" => raw_id}, socket) do
    {:ok, next_lect} =
      raw_id
      |> String.to_integer()
      |> Accounts.get_lecturer!()
      |> Accounts.disable_user()

    send_update(self(), LukasWeb.PagedList, id: "lecturers-list", entry_to_update: next_lect)

    {:noreply, socket}
  end

  def handle_event("enable-lecturer", %{"id" => raw_id}, socket) do
    {:ok, next_lect} =
      raw_id
      |> String.to_integer()
      |> Accounts.get_lecturer!()
      |> Accounts.enable_user()

    send_update(self(), LukasWeb.PagedList, id: "lecturers-list", entry_to_update: next_lect)

    {:noreply, socket}
  end

  def handle_info({:lecturers, :lecturer_registered, lecturer}, socket) do
    send_update(self(), LukasWeb.PagedList, id: "lecturers-list", reload: true)
    {:noreply, socket}
  end

  def handle_info({:lecturers, :lecturer_updated, _}, socket) do
    send_update(self(), LukasWeb.PagedList, id: "lecturers-list", reload: true)
    {:noreply, socket}
  end
end
