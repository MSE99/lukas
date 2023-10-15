defmodule LukasWeb.Operator.LecturersLive do
  use LukasWeb, :live_view

  alias Lukas.Accounts

  alias Phoenix.LiveView.AsyncResult
  alias LukasWeb.CommonComponents

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
    <.async_result assign={@loading}>
      <:loading>Loading...</:loading>
      <:failed>Failed to load lecturers...</:failed>

      <CommonComponents.navigate_breadcrumbs links={[
        {~p"/controls", "home"},
        {~p"/controls/lecturers", "lecturers"}
      ]} />

      <ul
        phx-update="stream"
        id="lecturers"
        phx-viewport-top={@page > 1 && "reached-top"}
        phx-viewport-bottom={@end_of_timeline? == false && "reached-bottom"}
        class={[
          @end_of_timeline? == false && "pb-[calc(200vh)]",
          @page > 1 && "pt-[calc(200vh)]",
          "mt-5"
        ]}
      >
        <li :for={{id, lect} <- @streams.lecturers} id={id} class="mb-3">
          <CommonComponents.user_record user={lect}>
            <:links :let={lect}>
              <.link
                navigate={~p"/controls/lecturers/#{lect.id}"}
                class="mr-auto text-secondary hover:underline"
              >
                <%= lect.name %>
              </.link>
            </:links>

            <:action :let={lect}>
              <.button
                :if={lect.enabled}
                id={"lecturer-#{lect.id}-disable"}
                phx-click="disable-lecturer"
                phx-value-id={lect.id}
              >
                Disable
              </.button>

              <.button
                :if={!lect.enabled}
                id={"lecturer-#{lect.id}-enable"}
                phx-click="enable-lecturer"
                phx-value-id={lect.id}
              >
                Enable
              </.button>
            </:action>
          </CommonComponents.user_record>
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
        {lecturers, per_page * 4 * -1, -1}
      else
        {Enum.reverse(lecturers), per_page * 4, 0}
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

  def handle_event("disable-lecturer", %{"id" => raw_id}, socket) do
    {:ok, next_lect} =
      raw_id
      |> String.to_integer()
      |> Accounts.get_lecturer!()
      |> Accounts.disable_user()

    {:noreply, socket |> stream_insert(:lecturers, next_lect)}
  end

  def handle_event("enable-lecturer", %{"id" => raw_id}, socket) do
    {:ok, next_lect} =
      raw_id
      |> String.to_integer()
      |> Accounts.get_lecturer!()
      |> Accounts.enable_user()

    {:noreply, socket |> stream_insert(:lecturers, next_lect)}
  end

  def handle_info({:lecturers, :lecturer_registered, lecturer}, socket) do
    if socket.assigns.page == 1 do
      {:noreply, socket |> stream_insert(:lecturers, lecturer) |> assign(:upper, lecturer.id)}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:lecturers, :lecturer_updated, _}, socket) do
    {:noreply, socket}
  end
end
