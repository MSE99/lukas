defmodule LukasWeb.InfiniteListLive do
  use LukasWeb, :live_component

  alias Lukas.IdList
  alias Phoenix.LiveView.AsyncResult

  slot :item, required: true

  def mount(socket) do
    {:ok, socket}
  end

  def update(%{delete: entry}, socket) do
    {:ok, stream_delete(socket, :items, entry)}
  end

  def update(%{replace: entry}, socket) when socket.assigns.enable_replace do
    %{ids_list: ids} = socket.assigns

    if IdList.has?(ids, entry.id) do
      {:ok, stream_insert(socket, :items, entry)}
    else
      {:ok, socket}
    end
  end

  def update(%{first_page_insert: entry}, socket) when entry != nil do
    if socket.assigns.page == 1 do
      {:ok,
       socket
       |> stream_insert(:items, entry, at: 0)
       |> sync_ids_list_for_first_page_insert(entry)}
    else
      {:ok, socket}
    end
  end

  def update(%{next_loader: next_loader, page: page, limit: limit}, socket)
      when is_function(next_loader) do
    next_items = next_loader.(page: page, limit: limit)

    next_socket =
      socket
      |> assign(:load, next_loader)
      |> assign(:page, page)
      |> assign(:limit, limit)
      |> stream(:items, next_items, reset: true)
      |> assign_ids_list_if_replace_enabled(next_items)

    {:ok, next_socket}
  end

  def update(assigns, socket) do
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
      |> assign(:enable_replace, Map.get(assigns, :enable_replace, false))
      |> start_async(:loading, fn ->
        assigns.load.(page: assigns.page, limit: assigns.limit)
      end)

    {:ok, next_socket}
  end

  defp sync_ids_list_for_first_page_insert(socket, entry)
       when socket.assigns.enable_replace do
    %{ids_list: ids} = socket.assigns
    next_ids = IdList.unshift(ids, [entry.id])
    assign(socket, ids_list: next_ids)
  end

  defp sync_ids_list_for_first_page_insert(socket, _), do: socket

  def handle_async(:loading, {:ok, items}, socket) do
    loaded_socket =
      socket
      |> assign_ids_list_if_replace_enabled(items)
      |> stream(:items, items)
      |> assign(:loading, AsyncResult.ok(socket.assigns.loading, nil))

    {:noreply, loaded_socket}
  end

  def handle_async(:loading, {:exit, reason}, socket) do
    {:noreply,
     socket
     |> assign(:loading, AsyncResult.failed(socket.assigns.loading, reason))}
  end

  defp assign_ids_list_if_replace_enabled(socket, items) when socket.assigns.enable_replace do
    ids_list =
      items
      |> Enum.map(fn item -> item.id end)
      |> IdList.new(socket.assigns.limit)

    socket
    |> assign(:ids_list, ids_list)
  end

  defp assign_ids_list_if_replace_enabled(socket, _), do: socket

  def render(assigns) do
    ~H"""
    <div>
      <.async_result assign={@loading}>
        <:loading>Loading...</:loading>
        <:failed>failed...</:failed>
        <ul
          id={@id}
          phx-update="stream"
          phx-viewport-top={@page > 1 && "reached-top"}
          phx-viewport-bottom={@end_of_timeline? == false && "reached-bottom"}
          class={[
            @end_of_timeline? == false && "pb-[calc(200vh)]",
            @page > 1 && "pt-[calc(200vh)]",
            "mt-5"
          ]}
          phx-target={@myself}
        >
          <li :for={{id, entry} <- @streams.items} id={id} class={get_css_classes_if_defined(@item)}>
            <%= render_slot(@item, entry) %>
          </li>
        </ul>
      </.async_result>
    </div>
    """
  end

  defp get_css_classes_if_defined(item_slot) do
    item_slot
    |> List.first()
    |> case do
      nil -> ""
      item -> Map.get(item, :class, "")
    end
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
        |> update_ids_list_if_replace_enabled(items, limit)
        |> assign(:end_of_timeline?, false)
        |> assign(:page, page)
        |> stream(:items, items, limit: limit, at: at)
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

  defp update_ids_list_if_replace_enabled(socket, items, limit)
       when socket.assigns.enable_replace do
    next_ids_list =
      IdList.concat(
        socket.assigns.ids_list,
        Enum.map(items, & &1.id),
        limit: limit
      )

    assign(socket, :ids_list, next_ids_list)
  end

  defp update_ids_list_if_replace_enabled(socket, _, _), do: socket
end
