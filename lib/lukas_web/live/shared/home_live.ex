defmodule LukasWeb.Shared.HomeLive do
  use LukasWeb, :live_view

  alias Phoenix.LiveView.AsyncResult
  alias Lukas.Learning

  def mount(_params, _session, socket) do
    next_socket =
      socket
      |> stream_configure(:latest_courses, [])
      |> stream_configure(:free_courses, [])
      |> assign(:loading, AsyncResult.loading())
      |> start_async(:loading, fn ->
        paid = Learning.list_courses(limit: 10, free: false)
        free = Learning.list_courses(limit: 10, free: true)
        %{paid: paid, free: free}
      end)

    {:ok, next_socket}
  end

  def handle_async(:loading, {:ok, %{paid: paid, free: free}}, socket) do
    {:noreply,
     socket
     |> stream(:latest_courses, paid)
     |> stream(:free_courses, free)
     |> assign(:loading, AsyncResult.ok(socket.assigns.loading, nil))}
  end

  def handle_async(:loading, {:exit, reason}, socket) do
    {:noreply, assign(socket, :loading, AsyncResult.failed(socket.assigns.loading, reason))}
  end

  def render(assigns) do
    ~H"""
    <.async_result assign={@loading}>
      <:loading><.loading_spinner /></:loading>
      <:failed>Failed...</:failed>

      <ul id="paid-courses" phx-update="stream">
        <li :for={{id, course} <- @streams.latest_courses} id={id}>
          <%= course.name %>
        </li>
      </ul>

      <ul id="free-courses" phx-update="stream">
        <li :for={{id, course} <- @streams.free_courses} id={id}>
          <%= course.name %>
        </li>
      </ul>
    </.async_result>
    """
  end
end
