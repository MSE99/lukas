defmodule LukasWeb.Lecturer.CourseEnrollmentsLive do
  use LukasWeb, :live_view

  alias Lukas.Learning

  def mount(%{"id" => raw_course_id}, _, socket) do
    with {course_id, _} <- Integer.parse(raw_course_id),
         {course, students} when course != nil <- Learning.get_course_with_students(course_id) do
      Learning.watch_course(course_id)

      {:ok, socket |> assign(course: course) |> stream(:students, students)}
    else
      _ -> {:ok, redirect(socket, to: ~p"/controls/courses")}
    end
  end

  def render(assigns) do
    ~H"""
    <h1>Enrollments</h1>

    <ul phx-update="stream" id="students">
      <li :for={{id, student} <- @streams.students} id={id}>
        <%= student.name %>
      </li>
    </ul>
    """
  end

  def handle_info({:course, _course_id, :student_enrolled, student}, socket) do
    {:noreply, stream_insert(socket, :students, student)}
  end

  def handle_info({:course, _, _, _}, socket), do: {:noreply, socket}
end
