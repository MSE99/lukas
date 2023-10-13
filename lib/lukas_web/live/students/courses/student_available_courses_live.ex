defmodule LukasWeb.Students.AvailableCoursesLive do
  use LukasWeb, :live_view

  alias Lukas.Learning
  alias Lukas.Learning.Course.Students

  def mount(_, _, socket) do
    Learning.watch_courses()
    Students.watch_student_enrollments(socket.assigns.current_user)

    available_courses = Students.list_open_courses_for_student(socket.assigns.current_user)
    {:ok, socket |> stream(:available_courses, available_courses)}
  end

  def render(assigns) do
    ~H"""
    <ul class="flex gap-1 text-lg text-secondary my-8">
      <li>
        <.link navigate={~p"/home"}>home</.link>
      </li>
      <li>
        /
      </li>
      <li>
        <.link navigate={~p"/home/courses/available"}>available courses</.link>
      </li>
    </ul>

    <ul id="available-courses" phx-update="stream">
      <li :for={{id, course} <- @streams.available_courses} id={id} class="mb-3 max-w-lg mx-auto">
        <.link
          navigate={~p"/home/courses/#{course.id}"}
          class=" flex h-[104px] bg-white shadow rounded text-secondary"
        >
          <img
            src={~p"/images/#{course.banner_image}"}
            width={110}
            height={104}
            class="w-[110px] h-[104px] rounded-tl-lg rounded-bl-lg"
          />

          <div class="p-3">
            <strong><%= course.name %></strong>

            <p>
              The description of the course lays here
            </p>
          </div>
        </.link>
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
