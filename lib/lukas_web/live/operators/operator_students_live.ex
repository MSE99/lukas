defmodule LukasWeb.Operator.StudentsLive do
  use LukasWeb, :live_view

  alias Lukas.Accounts

  alias Phoenix.LiveView.AsyncResult
  alias LukasWeb.CommonComponents

  def mount(_, _, socket) do
    next_socket =
      socket
      |> stream_configure(:students, [])
      |> assign(:page, 1)
      |> assign(:per_page, 50)
      |> assign(:end_of_timeline?, false)
      |> assign(:loading, AsyncResult.loading())
      |> start_async(:loading, fn ->
        Accounts.list_students(limit: 50, offset: 0)
      end)

    {:ok, next_socket}
  end

  def handle_async(:loading, {:ok, students}, socket) do
    Accounts.watch_students()

    {:noreply,
     socket
     |> assign(loading: AsyncResult.ok(socket.assigns.loading, nil))
     |> stream(:students, students, limit: socket.assigns.per_page, at: 0)}
  end

  def handle_async(:loading, {:exit, reason}, socket) do
    {:noreply, assign(socket, loading: AsyncResult.failed(socket.assigns.loading, reason))}
  end

  defp paginate_students(socket, page) when page >= 1 do
    %{per_page: per_page, page: current_page} = socket.assigns

    items = Accounts.list_students(limit: per_page * 3, offset: (page - 1) * per_page)

    {students, at, limit} =
      if page >= current_page do
        {items, -1, -1 * per_page * 3}
      else
        {Enum.reverse(items), 0, per_page * 3}
      end

    case students do
      [] ->
        assign(socket, :end_of_timeline?, at == -1)

      [_ | _] ->
        socket
        |> assign(:end_of_timeline?, false)
        |> assign(:page, page)
        |> stream(:students, students, at: at, limit: limit)
    end
  end

  def render(assigns) do
    ~H"""
    <.async_result assign={@loading}>
      <:loading>Loading students...</:loading>
      <:failed>Failed to load students</:failed>

      <CommonComponents.navigate_breadcrumbs links={[
        {~p"/controls", "home"},
        {~p"/controls/students", "students"}
      ]} />

      <ul
        id="students"
        phx-update="stream"
        phx-viewport-top={@page > 1 && "reached-top"}
        phx-viewport-bottom={@end_of_timeline? == false && "reached-bottom"}
        class={[
          @end_of_timeline? == false && "pb-[200vh]",
          @page > 1 && "pt-[200vh]"
        ]}
      >
        <li
          :for={{id, student} <- @streams.students}
          id={id}
          class={[!student.enabled && "opacity-25", "transition-all"]}
        >
          <div class="flex items-center">
            <img
              src={~p"/images/#{student.profile_image}"}
              width="50"
              height="50"
              class="w-[50px] h-[50px] rounded-full mr-3 lg:mr-5 border-4 border-primary-opaque"
            />

            <.link
              navigate={~p"/controls/students/#{student.id}"}
              class="mr-auto text-secondary hover:underline"
            >
              <%= student.name %>
            </.link>
            <.button
              :if={student.enabled}
              id={"student-#{student.id}-disable"}
              phx-click="disable-student"
              phx-value-id={student.id}
            >
              Disable
            </.button>

            <.button
              :if={!student.enabled}
              id={"student-#{student.id}-enable"}
              phx-click="enable-student"
              phx-value-id={student.id}
            >
              Enable
            </.button>
          </div>
        </li>
      </ul>
    </.async_result>
    """
  end

  def handle_event("disable-student", %{"id" => raw_id}, socket) do
    {:ok, next_student} =
      raw_id
      |> String.to_integer()
      |> Accounts.get_student!()
      |> Accounts.disable_user()

    {:noreply, socket |> stream_insert(:students, next_student)}
  end

  def handle_event("enable-student", %{"id" => raw_id}, socket) do
    {:ok, next_student} =
      raw_id
      |> String.to_integer()
      |> Accounts.get_student!()
      |> Accounts.enable_user()

    {:noreply, socket |> stream_insert(:students, next_student)}
  end

  def handle_event("reached-top", _, socket) do
    next_page =
      if socket.assigns.page == 1 do
        1
      else
        socket.assigns.page - 1
      end

    {:noreply, paginate_students(socket, next_page)}
  end

  def handle_event("reached-bottom", _, socket) do
    next_page = socket.assigns.page + 1
    {:noreply, paginate_students(socket, next_page)}
  end

  def handle_info({:students, :student_registered, student}, socket) do
    if socket.assigns.page == 1 do
      {:noreply, socket |> stream_insert(:students, student, at: 0)}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:students, :student_updated, _}, socket) do
    {:noreply, socket}
  end
end
