defmodule LukasWeb.Operator.CourseEnrollmentsLive do
  use LukasWeb, :live_view

  alias Lukas.Learning
  alias Lukas.Learning.Course.Students

  alias Phoenix.LiveView.AsyncResult
  alias LukasWeb.InfiniteListLive

  def mount(%{"id" => raw_course_id}, _, socket) do
    with {course_id, _} <- Integer.parse(raw_course_id) do
      {:ok,
       socket
       |> assign(:course, AsyncResult.loading())
       |> start_async(:course, fn ->
         Learning.get_course(course_id)
       end)}
    else
      _ -> {:ok, redirect(socket, to: ~p"/controls/courses")}
    end
  end

  def handle_async(:course, {:ok, course}, socket) when course == nil do
    {:noreply, redirect(socket, to: ~p"/controls/courses")}
  end

  def handle_async(:course, {:ok, course}, socket) do
    Learning.watch_course(course.id)

    {:noreply,
     socket
     |> assign(:course, AsyncResult.ok(socket.assigns.course, course))}
  end

  def handle_async(:course, {:exit, reason}, socket) do
    {:noreply, assign(socket, :course, AsyncResult.failed(socket.assigns.course, reason))}
  end

  def render(assigns) do
    ~H"""
    <h1>Enrollments</h1>

    <.async_result :let={course} assign={@course}>
      <:loading>Loading course...</:loading>
      <:failed>Failed to load course...</:failed>

      <h3><%= course.name %></h3>

      <.live_component
        module={InfiniteListLive}
        id="enrollments"
        page={1}
        limit={50}
        entry_dom_id={fn entry -> "enrollments-#{entry.id}" end}
        load={fn opts -> Students.list_enrolled(course.id, opts) end}
      >
        <:item :let={student}>
          <%= student.name %>
        </:item>
      </.live_component>
    </.async_result>
    """
  end

  def handle_info({:course, _course_id, :student_enrolled, student}, socket) do
    send_update(self(), InfiniteListLive, id: "enrollments", first_page_insert: student)
    {:noreply, socket}
  end

  def handle_info({:course, _, _, _}, socket), do: {:noreply, socket}
end
