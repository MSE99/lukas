defmodule LukasWeb.Operator.CourseLessonsLive do
  use LukasWeb, :live_view

  alias Lukas.Learning

  alias Phoenix.LiveView.AsyncResult

  def mount(params, _session, socket) do
    {:ok,
     socket
     |> stream_configure(:lessons, [])
     |> assign(:loading, AsyncResult.loading())
     |> start_async(:loading, fn -> load_course_with_lessons(params) end)}
  end

  defp load_course_with_lessons(%{"id" => raw_id}) do
    with {id, _} <- Integer.parse(raw_id), course when course != nil <- Learning.get_course(id) do
      lessons = Learning.get_lessons(course)
      {course, lessons}
    else
      _ -> :error
    end
  end

  def handle_async(:loading, {:ok, {course, lessons}}, socket) do
    Learning.watch_course(course)

    next_socket =
      socket
      |> assign(:loading, AsyncResult.ok(socket.assigns.loading, nil))
      |> assign(:course, course)
      |> stream(:lessons, lessons)

    {:noreply, next_socket}
  end

  def handle_async(:loading, {:ok, :error}, socket) do
    {:noreply, redirect(socket, to: ~p"/controls/courses")}
  end

  def handle_async(:loading, {:exit, reason}, socket) do
    next_socket =
      socket
      |> assign(:loading, AsyncResult.failed(socket.assigns.loading, reason))

    {:noreply, next_socket}
  end

  def render(assigns) do
    ~H"""
    <.async_result assign={@loading}>
      <:loading><.loading_spinner /></:loading>
      <:failed>Failed...</:failed>

      <h1><%= @course.name %></h1>

      <ul id="lessons" phx-update="stream">
        <li :for={{id, lesson} <- @streams.lessons} id={id}>
          <%= lesson.title %>
        </li>
      </ul>
    </.async_result>
    """
  end

  def handle_info({:course, _, :lesson_added, lesson}, socket) do
    {:noreply, stream_insert(socket, :lessons, lesson)}
  end

  def handle_info({:course, _, :lesson_deleted, lesson}, socket) do
    {:noreply, stream_delete(socket, :lessons, lesson)}
  end

  def handle_info({:course, _, :lesson_updated, lesson}, socket) do
    {:noreply, stream_insert(socket, :lessons, lesson)}
  end

  def handle_info({:course, _, :course_updated, course}, socket) do
    {:noreply, assign(socket, :course, course)}
  end

  def handle_info({:course, _, _, _}, socket), do: {:noreply, socket}
end
