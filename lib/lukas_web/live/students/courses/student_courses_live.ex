defmodule LukasWeb.Students.CoursesLive do
  use LukasWeb, :live_view

  alias Phoenix.LiveView.AsyncResult
  alias Lukas.Learning.Course.Students
  alias LukasWeb.CommonComponents

  def mount(_, _, socket) do
    next_socket =
      socket
      |> stream_configure(:courses, [])
      |> assign(:loading, AsyncResult.loading())
      |> start_async(:loading, fn ->
        Students.list_student_courses(socket.assigns.current_user)
      end)

    {:ok, next_socket}
  end

  def handle_async(:loading, {:ok, courses}, socket) do
    Students.watch_student_enrollments(socket.assigns.current_user)

    {:noreply,
     socket
     |> assign(:loading, AsyncResult.ok(socket.assigns.loading, nil))
     |> stream(:courses, courses)}
  end

  def handle_async(:loading, {:exit, reason}, socket) do
    {:noreply, assign(socket, :loading, AsyncResult.failed(socket.assigns.loading, reason))}
  end

  def render(assigns) do
    ~H"""
    <CommonComponents.navigate_breadcrumbs links={[
      {~p"/home", gettext("home")},
      {~p"/home/courses", gettext("my courses")}
    ]} />

    <.async_result assign={@loading}>
      <:loading>Loading courses...</:loading>
      <:failed>Failed to load courses courses.</:failed>

      <ul id="courses" phx-update="stream">
        <li :for={{id, course} <- @streams.courses} id={id} class="mb-3 max-w-md mx-auto">
          <.link navigate={~p"/home/courses/#{course.id}"}>
            <CommonComponents.course_card
              course={course}
              banner_image_url={~p"/home/courses/#{course.id}/banner"}
            />
          </.link>
        </li>
      </ul>
    </.async_result>
    """
  end

  def handle_info({:enrollments, :enrolled, course}, socket) do
    {:noreply, socket |> stream_insert(:courses, course)}
  end
end
