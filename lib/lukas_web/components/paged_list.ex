defmodule LukasWeb.PagedList do
  use LukasWeb, :live_component

  alias Phoenix.LiveView.AsyncResult

  slot :item, required: true

  def mount(socket) do
    {:ok, socket}
  end

  def update(assigns, socket) do
    case assigns do
      %{entry_to_update: entry} when entry != nil ->
        {:ok, socket |> stream_insert(:items, entry)}

      %{first_page_insert: entry} when entry != nil ->
        if socket.assigns.page == 1 do
          {:ok, socket |> stream_insert(:items, entry)}
        else
          {:ok, socket}
        end

      _ ->
        next_socket =
          socket
          |> stream_configure(:items, dom_id: assigns.entry_dom_id)
          |> assign(:id, assigns.id)
          |> assign(:page, assigns.page)
          |> assign(:limit, assigns.limit)
          |> assign(:end_of_timeline?, false)
          |> assign(:loading, AsyncResult.loading())
          |> assign(:inner_block, assigns.inner_block)
          |> assign(:item, assigns.item)
          |> assign(:load, assigns.load)
          |> start_async(:loading, fn ->
            assigns.load.(page: assigns.page, limit: assigns.limit)
          end)

        {:ok, next_socket}
    end
  end

  def handle_async(:loading, {:ok, items}, socket) do
    {:noreply,
     socket
     |> stream(:items, items)
     |> assign(:loading, AsyncResult.ok(socket.assigns.loading, nil))}
  end

  def handle_async(:loading, {:exit, reason}, socket) do
    {:noreply,
     socket
     |> assign(:loading, AsyncResult.failed(socket.assigns.loading, reason))}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.async_result assign={@loading}>
        <:loading>Loading...</:loading>
        <:failed>Failed...</:failed>

        <ul
          phx-update="stream"
          id={@id}
          phx-viewport-top={@page > 1 && "reached-top"}
          phx-viewport-bottom={@end_of_timeline? == false && "reached-bottom"}
          class={[
            @end_of_timeline? == false && "pb-[calc(200vh)]",
            @page > 1 && "pt-[calc(200vh)]",
            "mt-5"
          ]}
          phx-target={@myself}
        >
          <li :for={{id, entry} <- @streams.items} id={id}>
            <%= render_slot(@item, entry) %>
          </li>
        </ul>
      </.async_result>
    </div>
    """
  end

  defp paginate(socket, page) when page >= 1 do
    %{page: current_page, limit: per_page} = socket.assigns

    loaded = socket.assigns.load.(limit: per_page, offset: (page - 1) * per_page)

    {items, limit, at} =
      if page >= current_page do
        {loaded, per_page * 3 * -1, -1}
      else
        {Enum.reverse(loaded), per_page * 3, 0}
      end

    case items do
      [] ->
        socket
        |> assign(:end_of_timeline?, at == -1)

      [_ | _] ->
        socket
        |> assign(:end_of_timeline?, false)
        |> assign(:page, page)
        |> stream(:courses, items, limit: limit, at: at)
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
end
