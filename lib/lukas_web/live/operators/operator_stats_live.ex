defmodule LukasWeb.Operator.StatsLive do
  use LukasWeb, :live_view

  alias Lukas.Learning
  alias Phoenix.LiveView.AsyncResult

  def mount(_, _, socket) do
    next_socket =
      socket
      |> assign(:loading, AsyncResult.loading())
      |> start_async(:loading, fn -> load_data() end)

    {:ok, next_socket}
  end

  defp load_data() do
    courses_count = Learning.count_courses()
    courses_count
  end

  def handle_async(:loading, {:ok, count}, socket) do
    {:noreply,
     assign(socket, :loading, AsyncResult.ok(socket.assigns.loading, nil))
     |> assign(:courses_count, count)}
  end

  def handle_async(:loading, {:exit, reason}, socket) do
    {:noreply, assign(socket, :loading, AsyncResult.failed(socket.assigns.loading, reason))}
  end

  def render(assigns) do
    ~H"""
    <.async_result assign={@loading}>
      <:loading><.loading_spinner /></:loading>
      <:failed>Failed to load...</:failed>
      <%= @courses_count %> <%= gettext("Courses") %>
    </.async_result>
    """
  end
end
