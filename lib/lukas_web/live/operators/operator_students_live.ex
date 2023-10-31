defmodule LukasWeb.Operator.StudentsLive do
  use LukasWeb, :live_view

  alias Lukas.Accounts

  alias LukasWeb.CommonComponents
  alias LukasWeb.InfiniteListLive

  def mount(_, _, socket) do
    if connected?(socket) do
      Accounts.watch_students()
    end

    {:ok, socket |> assign(:search_name, "")}
  end

  def render(assigns) do
    ~H"""
    <CommonComponents.navigate_breadcrumbs links={[
      {~p"/controls", gettext("home")},
      {~p"/controls/students", gettext("students")}
    ]} />

    <form id="search-form" phx-submit="search" class="mb-3">
      <label for="name" class="text-secondary font-bold px-3">
        <%= gettext("Search") %>
      </label>

      <input
        type="text"
        name="name"
        value={@search_name}
        class="w-full mt-3 rounded-full border-0 shadow"
      />
    </form>

    <.live_component
      module={InfiniteListLive}
      id="students-list"
      entry_dom_id={fn entry -> "students-#{entry.id}" end}
      page={1}
      limit={50}
      load={fn opts -> Accounts.list_students(opts) end}
      enable_replace={true}
    >
      <:item :let={student}>
        <CommonComponents.user_record user={student}>
          <:links>
            <.link
              navigate={~p"/controls/students/#{student.id}"}
              class="me-auto text-secondary hover:underline"
            >
              <%= student.name %>
            </.link>
          </:links>

          <:action :let={student}>
            <.button
              :if={student.enabled}
              id={"student-#{student.id}-disable"}
              phx-click="disable-student"
              phx-value-id={student.id}
            >
              <%= gettext("Disable") %>
            </.button>

            <.button
              :if={!student.enabled}
              id={"student-#{student.id}-enable"}
              phx-click="enable-student"
              phx-value-id={student.id}
            >
              <%= gettext("Enable") %>
            </.button>
          </:action>
        </CommonComponents.user_record>
      </:item>
    </.live_component>
    """
  end

  def handle_event("disable-student", %{"id" => raw_id}, socket) do
    {:ok, _} =
      raw_id
      |> String.to_integer()
      |> Accounts.get_student!()
      |> Accounts.disable_user()

    {:noreply, socket}
  end

  def handle_event("enable-student", %{"id" => raw_id}, socket) do
    {:ok, _} =
      raw_id
      |> String.to_integer()
      |> Accounts.get_student!()
      |> Accounts.enable_user()

    {:noreply, socket}
  end

  def handle_event("search", %{"name" => name}, socket) do
    cleaned = String.trim(name)

    send_update(
      self(),
      LukasWeb.InfiniteListLive,
      id: "students-list",
      page: 1,
      limit: 50,
      next_loader: fn opts ->
        opts
        |> Keyword.put(:name, cleaned)
        |> Accounts.list_students()
      end
    )

    {:noreply, socket}
  end

  def handle_info({:students, :student_registered, student}, socket) do
    send_update(self(), InfiniteListLive, id: "students-list", first_page_insert: student)
    {:noreply, socket}
  end

  def handle_info({:students, :student_updated, student}, socket) do
    send_update(self(), InfiniteListLive, id: "students-list", replace: student)
    {:noreply, socket}
  end
end
