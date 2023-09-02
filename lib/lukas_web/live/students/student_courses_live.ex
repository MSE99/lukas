defmodule LukasWeb.Students.CoursesLive do
  use LukasWeb, :live_view

  alias Lukas.Learning

  def mount(_, _, socket) do
    Learning.watch_student_enrollments(socket.assigns.current_user)
    courses = Learning.list_student_courses(socket.assigns.current_user)

    {:ok, socket |> stream(:courses, courses)}
  end

  def render(assigns) do
    ~H"""
    <h1>Courses</h1>

    <ul id="courses" phx-update="stream">
      <li :for={{id, course} <- @streams.courses} id={id}>
        <%= course.name %>
      </li>
    </ul>
    """
  end

  def handle_info({:enrollments, :enrolled, course}, socket) do
    {:noreply, socket |> stream_insert(:courses, course)}
  end
end
