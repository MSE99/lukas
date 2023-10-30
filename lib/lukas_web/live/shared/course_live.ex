defmodule LukasWeb.Shared.CourseLive do
  use LukasWeb, :live_view

  alias Lukas.Learning
  alias Lukas.Learning.Course.Staff
  alias Phoenix.LiveView.AsyncResult

  def mount(%{"id" => raw_id}, _, socket) do
    with {id, _} <- Integer.parse(raw_id) do
      {:ok, begin_loading_course(socket, id)}
    else
      _ -> {:ok, redirect(socket, to: ~p"/")}
    end
  end

  defp begin_loading_course(socket, id) do
    socket
    |> assign(:loading, AsyncResult.loading())
    |> start_async(:loading, fn -> Staff.get_course_with_lecturers(id) end)
  end

  def handle_async(:loading, {:ok, {nil, _, _}}, socket) do
    {:noreply, redirect(socket, to: ~p"/")}
  end

  def handle_async(:loading, {:ok, {course, lecturers, tags}}, socket) do
    Learning.watch_course(course)

    next_socket =
      socket
      |> assign(:loading, AsyncResult.ok(socket.assigns.loading, nil))
      |> assign(:course, course)
      |> stream(:lecturers, lecturers)
      |> stream(:tags, tags)

    {:noreply, next_socket}
  end

  def handle_async(:loading, {:exit, reason}, socket) do
    {:noreply, assign(socket, loading: AsyncResult.failed(socket.assigns.loading, reason))}
  end

  def render(assigns) do
    ~H"""
    <.async_result assign={@loading}>
      <:loading>
        <.loading_spinner />
      </:loading>

      <:failed>Failed to load course...</:failed>

      <%= @course.name %>
      <%= @course.price |> :erlang.float_to_binary(decimals: 1) %> LYD
      <div phx-update="stream" id="lecturers">
        <span :for={{id, lect} <- @streams.lecturers} id={id}>
          <%= lect.name %>
        </span>
      </div>

      <div phx-update="stream" id="tags">
        <span :for={{id, tag} <- @streams.tags} id={id}>
          <%= tag.name %>
        </span>
      </div>
    </.async_result>
    """
  end

  def handle_info({:course, _, :course_updated, next}, socket) do
    {:noreply, assign(socket, :course, next)}
  end

  def handle_info({:course, _, :lecturer_added, lect}, socket) do
    {:noreply, stream_insert(socket, :lecturers, lect)}
  end

  def handle_info({:course, _, :lecturer_removed, lect}, socket) do
    {:noreply, stream_delete(socket, :lecturers, lect)}
  end
end
