defmodule LukasWeb.Lecturers.CoursesLive do
  use LukasWeb, :live_view

  alias Lukas.Learning

  def mount(_, _, socket) do
    lecturer = socket.assigns.current_user

    Learning.Course.Staff.watch_staff_status(lecturer.id)

    courses = Learning.Course.Staff.list_lecturer_courses(lecturer.id)
    {:ok, socket |> stream(:courses, courses)}
  end

  def render(assigns) do
    ~H"""
    <h1>My courses</h1>

    <ul id="courses" phx-update="stream">
      <li :for={{id, course} <- @streams.courses} id={id}>
        <%= course.name %>
      </li>
    </ul>
    """
  end

  def handle_info({:staff_status, :added_to_course, course}, socket) do
    {:noreply, stream_insert(socket, :courses, course)}
  end

  def handle_info({:staff_status, :removed_from_course, course}, socket) do
    {:noreply, stream_delete(socket, :courses, course)}
  end
end
