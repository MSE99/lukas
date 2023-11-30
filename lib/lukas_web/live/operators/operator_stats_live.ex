defmodule LukasWeb.Operator.StatsLive do
  use LukasWeb, :live_view

  alias Lukas.Stats
  alias Phoenix.LiveView.AsyncResult

  import LukasWeb.CommonComponents

  def mount(_, _, socket) do
    next_socket =
      socket
      |> assign(:loading, AsyncResult.loading())
      |> start_async(:loading, fn -> load_data() end)

    {:ok, next_socket}
  end

  defp load_data() do
    courses_count = Stats.count_courses()
    students_count = Stats.count_students()

    %{courses_count: courses_count, students_count: students_count}
  end

  def handle_async(:loading, {:ok, result}, socket) do
    %{courses_count: courses_count, students_count: students_count} = result

    {:noreply,
     socket
     |> assign(:loading, AsyncResult.ok(socket.assigns.loading, nil))
     |> assign(:courses_count, courses_count)
     |> assign(:students_count, students_count)}
  end

  def handle_async(:loading, {:exit, reason}, socket) do
    {:noreply, assign(socket, :loading, AsyncResult.failed(socket.assigns.loading, reason))}
  end

  def render(assigns) do
    ~H"""
    <.async_result assign={@loading}>
      <:loading><.loading_spinner /></:loading>
      <:failed>Failed to load...</:failed>

      <.navigate_breadcrumbs links={[
        {~p"/controls", gettext("home")},
        {~p"/controls/stats", gettext("stats")}
      ]} />

      <div>
        <%= gettext("Number of students in the system") %>
        <%= @students_count %>
      </div>

      <div>
        <%= gettext("Number of courses in the system") %>
        <%= @courses_count %>
      </div>
    </.async_result>
    """
  end
end
