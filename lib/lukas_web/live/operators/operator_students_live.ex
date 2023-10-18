defmodule LukasWeb.Operator.StudentsLive do
  use LukasWeb, :live_view

  alias Lukas.Accounts

  alias LukasWeb.CommonComponents
  alias LukasWeb.InfiniteListLive

  def mount(_, _, socket) do
    if connected?(socket) do
      Accounts.watch_students()
    end

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <CommonComponents.navigate_breadcrumbs links={[
      {~p"/controls", "home"},
      {~p"/controls/students", "students"}
    ]} />

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
              class="mr-auto text-secondary hover:underline"
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
              Disable
            </.button>

            <.button
              :if={!student.enabled}
              id={"student-#{student.id}-enable"}
              phx-click="enable-student"
              phx-value-id={student.id}
            >
              Enable
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

  def handle_info({:students, :student_registered, student}, socket) do
    send_update(self(), InfiniteListLive, id: "students-list", first_page_insert: student)
    {:noreply, socket}
  end

  def handle_info({:students, :student_updated, student}, socket) do
    send_update(self(), InfiniteListLive, id: "students-list", replace: student)
    {:noreply, socket}
  end
end
