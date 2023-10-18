defmodule LukasWeb.Students.AvailableCoursesLive do
  use LukasWeb, :live_view

  alias Lukas.Learning
  alias Lukas.Learning.Course.Students
  alias LukasWeb.CommonComponents

  alias LukasWeb.InfiniteListLive

  def mount(_, _, socket) do
    if connected?(socket) do
      Learning.watch_courses()
      Students.watch_student_enrollments(socket.assigns.current_user)
    end

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <CommonComponents.navigate_breadcrumbs links={[
      {~p"/home", "home"},
      {~p"/home/courses/available", "available courses"}
    ]} />

    <.live_component
      module={InfiniteListLive}
      id="courses-list"
      page={1}
      limit={50}
      load={fn opts -> Students.list_open_courses_for_student(@current_user, opts) end}
      entry_dom_id={fn course -> "courses-#{course.id}" end}
    >
      <:item :let={course}>
        <.link navigate={~p"/home/courses/#{course.id}"}>
          <CommonComponents.course_card course={course} />
        </.link>
      </:item>
    </.live_component>
    """
  end

  def handle_info({:courses, :course_created, course}, socket) do
    send_update(self(), InfiniteListLive, id: "courses-list", first_page_insert: course)
    {:noreply, socket}
  end

  def handle_info({:courses, :course_updated, _}, socket) do
    {:noreply, socket}
  end

  def handle_info({:enrollments, :enrolled, course}, socket) do
    send_update(self(), InfiniteListLive, id: "courses-list", delete: course)
    {:noreply, socket}
  end
end
