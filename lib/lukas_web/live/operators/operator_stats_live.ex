defmodule LukasWeb.Operator.StatsLive do
  use LukasWeb, :live_view

  alias Lukas.Stats
  alias Lukas.Money

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
    earnings = Stats.get_total_earnings()
    months = Money.calculate_profits_12_months_ago()

    %{
      courses_count: courses_count,
      students_count: students_count,
      earnings: earnings,
      months: months
    }
  end

  def handle_async(:loading, {:ok, result}, socket) do
    %{
      courses_count: courses_count,
      students_count: students_count,
      earnings: earnings,
      months: months
    } = result

    svg =
      months
      |> Enum.map(fn {date, amount} -> ["#{date.year}/#{date.month}/#{date.day}", amount] end)
      |> Contex.Dataset.new(["date", "earnings"])
      |> Contex.Plot.new(Contex.BarChart, 600, 400)
      |> Contex.Plot.to_svg()

    {:noreply,
     socket
     |> assign(:loading, AsyncResult.ok(socket.assigns.loading, nil))
     |> assign(:courses_count, courses_count)
     |> assign(:students_count, students_count)
     |> assign(earnings: earnings)
     |> assign(months: months)
     |> assign(svg: svg)}
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

      <div dir="ltr">
        <%= @svg %>
      </div>

      <div>
        <%= gettext("Total money earned") %>
        <%= @earnings |> :erlang.float_to_binary(decimals: 1) %>
      </div>
    </.async_result>
    """
  end
end
