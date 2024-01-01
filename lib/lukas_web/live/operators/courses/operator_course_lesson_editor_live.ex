defmodule LukasWeb.Operator.LessonEditorLive do
  use LukasWeb, :live_view

  alias Lukas.Learning
  alias Phoenix.LiveView.AsyncResult

  def mount(%{"id" => raw_course_id}, _, socket) do
    next_socket =
      socket
      |> start_async(:loading, fn -> load_course(raw_course_id) end)
      |> assign(:loading, AsyncResult.loading())

    {:ok, next_socket, layout: {LukasWeb.Layouts, :frameless}}
  end

  defp load_course(raw_id) do
    with {id, _} <- Integer.parse(raw_id),
         course when course != nil <- Learning.get_course(id) do
      course
    else
      _ -> :error
    end
  end

  def handle_async(:loading, {:exit, _}, socket) do
    {:noreply,
     socket
     |> assign(:loading, AsyncResult.failed(socket.assigns.loading, "Course not found"))
     |> redirect(to: ~p"/controls/courses")}
  end

  def handle_async(:loading, {:ok, :error}, socket) do
    {:noreply,
     socket
     |> assign(:loading, AsyncResult.failed(socket.assigns.loading, "Course not found"))
     |> redirect(to: ~p"/controls/courses")}
  end

  def handle_async(:loading, {:ok, course}, socket) do
    {:noreply,
     socket
     |> assign(:loading, AsyncResult.ok(socket.assigns.loading, course))
     |> assign(:course, course)}
  end

  def render(assigns) do
    ~H"""
    <.async_result assign={@loading}>
      <:loading>
        <.loading_spinner />
      </:loading>
      <:failed>Failed to load course...</:failed>
      <!-- JS land -->
      <div id="lesson-editor" phx-update="ignore"></div>
    </.async_result>
    """
  end
end
