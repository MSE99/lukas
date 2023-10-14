defmodule LukasWeb.Students.AvailableCoursesLive do
  use LukasWeb, :live_view

  alias Lukas.Learning
  alias Lukas.Learning.Course.Students
  alias LukasWeb.CommonComponents

  alias Phoenix.LiveView.AsyncResult

  def mount(_, _, socket) do
    next_socket =
      socket
      |> stream_configure(:courses, [])
      |> assign(:loading, AsyncResult.loading())
      |> start_async(:loading, fn ->
        Students.list_open_courses_for_student(socket.assigns.current_user)
      end)

    {:ok, next_socket}
  end

  def handle_async(:loading, {:ok, courses}, socket) do
    Learning.watch_courses()
    Students.watch_student_enrollments(socket.assigns.current_user)

    next_socket =
      socket
      |> stream(:available_courses, courses)
      |> assign(:loading, AsyncResult.ok(socket.assigns.loading, nil))

    {:noreply, next_socket}
  end

  def handle_async(:loading, {:exit, reason}, socket) do
    {:noreply, assign(socket, :loading, AsyncResult.failed(socket.assigns.loading, reason))}
  end

  def render(assigns) do
    ~H"""
    <CommonComponents.navigate_breadcrumbs links={[
      {~p"/home", "home"},
      {~p"/home/courses/available", "available courses"}
    ]} />

    <.async_result assign={@loading}>
      <.async_result assign={@loading}>
        <:loading>Loading courses...</:loading>
        <:failed>Failed to load courses courses.</:failed>

        <ul id="courses" phx-update="stream">
          <li :for={{id, course} <- @streams.available_courses} id={id} class="mb-3 max-w-lg mx-auto">
            <.link navigate={~p"/home/courses/#{course.id}"}>
              <CommonComponents.course_card course={course} />
            </.link>
          </li>
        </ul>
      </.async_result>
    </.async_result>
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
