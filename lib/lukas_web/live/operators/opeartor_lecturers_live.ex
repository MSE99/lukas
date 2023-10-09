defmodule LukasWeb.Operator.LecturersLive do
  use LukasWeb, :live_view

  alias Lukas.Accounts
  alias Phoenix.LiveView.AsyncResult

  def mount(_, _, socket) do
    next_socket =
      socket
      |> stream_configure(:lecturer, [])
      |> assign(:loading, AsyncResult.loading())
      |> start_async(:loading, fn ->
        Accounts.list_lecturers(limit: 50, offset: 0)
      end)

    {:ok, next_socket}
  end

  def handle_async(:loading, {:ok, lecturers}, socket) do
    Accounts.watch_lecturers()

    next_socket =
      socket
      |> assign(:page, 1)
      |> assign(:per_page, 50)
      |> assign(:end_of_timeline?, false)
      |> stream(:lecturers, lecturers, limit: 50, at: 0)
      |> assign(:loading, AsyncResult.ok(socket.assigns.loading, nil))

    {:noreply, next_socket}
  end

  def handle_async(:loading, {:exit, reason}, socket) do
    {:noreply, assign(socket, AsyncResult.failed(socket.assigns.loading, reason))}
  end

  def render(assigns) do
    ~H"""
    <h1>Lecturers in the system</h1>

    <.async_result assign={@loading}>
      <:loading>Loading...</:loading>
      <:failed>Failed to load lecturers...</:failed>

      <ul
        phx-update="stream"
        id="lecturers"
        phx-viewport-top={@page > 1 && "reached-top"}
        phx-viewport-bottom={@end_of_timeline? == false && "reached-bottom"}
        class={[
          @end_of_timeline? == false && "pb-[200vh]",
          @page > 1 && "pt-[200vh]"
        ]}
      >
        <li :for={{id, lect} <- @streams.lecturers} id={id}>
          <%= lect.name %>
        </li>
      </ul>
    </.async_result>
    """
  end

  defp paginate(socket, page) when page >= 1 do
    %{page: current_page, per_page: per_page} = socket.assigns

    lecturers = Accounts.list_lecturers(limit: per_page, offset: (page - 1) * per_page)

    {items, limit, at} =
      if page >= current_page do
        {lecturers, per_page * 3 * -1, -1}
      else
        {Enum.reverse(lecturers), per_page * 3, 0}
      end

    case items do
      [] ->
        socket
        |> assign(:end_of_timeline?, at == -1)

      [_ | _] ->
        socket
        |> assign(:page, page)
        |> assign(:end_of_timeline?, false)
        |> stream(:lecturers, items, at: at, limit: limit)
    end
  end

  def handle_event("reached-top", _, socket) do
    next_page =
      if socket.assigns.page == 1 do
        1
      else
        socket.assigns.page - 1
      end

    {:noreply, paginate(socket, next_page)}
  end

  def handle_event("reached-bottom", _, socket) do
    next_page = socket.assigns.page + 1
    {:noreply, paginate(socket, next_page)}
  end

  def handle_info({:lecturers, :lecturer_registered, lecturer}, socket) do
    if socket.assigns.page == 1 do
      {:noreply, stream_insert(socket, :lecturers, lecturer)}
    else
      {:noreply, socket}
    end
  end
end