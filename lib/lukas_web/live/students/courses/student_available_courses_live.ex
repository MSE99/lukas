defmodule LukasWeb.Students.AvailableCoursesLive do
  use LukasWeb, :live_view

  alias Lukas.Learning

  def mount(_, _, socket) do
    Learning.watch_courses()
    Learning.watch_student_enrollments(socket.assigns.current_user)

    available_courses = Learning.list_open_courses_for_student(socket.assigns.current_user)
    {:ok, socket |> stream(:available_courses, available_courses)}
  end

  def render(assigns) do
    ~H"""
    <h1>Available courses</h1>

    <ul id="available-courses" phx-update="stream">
      <li :for={{id, course} <- @streams.available_courses} id={id}>
        <.link navigate={~p"/home/courses/#{course.id}"}><%= course.name %></.link>
      </li>
    </ul>
    """
  end

  def handle_info({:courses, :course_created, course}, socket) do
    {:noreply, stream_insert(socket, :available_courses, course)}
  end

  def handle_info({:courses, :course_updated, _}, socket) do
    {:noreply, socket}
  end

  def handle_info({:enrollments, :enrolled, course}, socket) do
    {:noreply, stream_delete(socket, :available_courses, course)}
  end
end
