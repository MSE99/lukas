defmodule LukasWeb.Operator.LecturersLive do
  use LukasWeb, :live_view

  alias Lukas.Accounts
  alias LukasWeb.CommonComponents

  def mount(_, _, socket) do
    if connected?(socket) do
      Accounts.watch_lecturers()
    end

    {:ok, socket |> assign(:search_name, "")}
  end

  def render(assigns) do
    ~H"""
    <CommonComponents.navigate_breadcrumbs links={[
      {~p"/controls", "home"},
      {~p"/controls/lecturers", "lecturers"}
    ]} />

    <form id="search-form" phx-submit="search" class="mb-3">
      <label for="name" class="text-secondary font-bold px-3">Search</label>

      <input
        type="text"
        name="name"
        value={@search_name}
        class="w-full mt-3 rounded-full border-0 shadow"
      />
    </form>

    <.live_component
      module={LukasWeb.InfiniteListLive}
      id="lecturers-list"
      page={1}
      limit={50}
      load={fn opts -> Accounts.list_lecturers(opts) end}
      entry_dom_id={fn lect -> "lecturers-#{lect.id}" end}
      enable_replace={true}
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

    send_update(self(), LukasWeb.InfiniteListLive, id: "lecturers-list", replace: next_lect)

    {:noreply, socket}
  end

  def handle_event("enable-lecturer", %{"id" => raw_id}, socket) do
    {:ok, next_lect} =
      raw_id
      |> String.to_integer()
      |> Accounts.get_lecturer!()
      |> Accounts.enable_user()

    send_update(self(), LukasWeb.InfiniteListLive, id: "lecturers-list", replace: next_lect)

    {:noreply, socket}
  end

  def handle_event("search", %{"name" => name}, socket) do
    cleaned = name |> String.trim()

    send_update(
      self(),
      LukasWeb.InfiniteListLive,
      id: "lecturers-list",
      page: 1,
      limit: 50,
      next_loader: fn opts ->
        opts
        |> Keyword.put(:name, cleaned)
        |> Accounts.list_lecturers()
      end
    )

    {:noreply, assign(socket, :search_name, cleaned)}
  end

  def handle_info({:lecturers, :lecturer_registered, lecturer}, socket) do
    send_update(
      self(),
      LukasWeb.InfiniteListLive,
      id: "lecturers-list",
      first_page_insert: lecturer
    )

    {:noreply, socket}
  end

  def handle_info({:lecturers, :lecturer_updated, lecturer}, socket) do
    send_update(self(), LukasWeb.InfiniteListLive, id: "lecturers-list", replace: lecturer)
    {:noreply, socket}
  end
end
