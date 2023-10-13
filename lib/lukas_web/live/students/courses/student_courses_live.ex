defmodule LukasWeb.Students.CoursesLive do
  use LukasWeb, :live_view

  alias Lukas.Learning.Course.Students

  def mount(_, _, socket) do
    Students.watch_student_enrollments(socket.assigns.current_user)
    courses = Students.list_student_courses(socket.assigns.current_user)
    {:ok, socket |> stream(:courses, courses)}
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
        <.link navigate={~p"/home/courses"}>my courses</.link>
      </li>
    </ul>

    <ul id="courses" phx-update="stream">
      <li :for={{id, course} <- @streams.courses} id={id} class="mb-3 max-w-lg mx-auto">
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

  def handle_info({:enrollments, :enrolled, course}, socket) do
    {:noreply, socket |> stream_insert(:courses, course)}
  end
end
