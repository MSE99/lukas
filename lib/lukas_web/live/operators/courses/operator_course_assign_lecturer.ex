defmodule LukasWeb.Operator.AssignLecturerLive do
  use LukasWeb, :live_view

  alias Lukas.Accounts
  alias Lukas.Learning
  alias Lukas.Learning.Course.Staff

  alias Phoenix.LiveView.AsyncResult
  alias LukasWeb.CommonComponents

  def mount(%{"id" => raw_course_id}, _, socket) do
    with {id, _} <- Integer.parse(raw_course_id),
         course when course != nil <- Learning.get_course(id) do
      next_socket =
        socket
        |> assign(:course, course)
        |> assign(:loading, AsyncResult.loading())
        |> start_async(:loading, fn -> load_lecturers(course) end)
        |> stream_configure(:lecturers, [])

      {:ok, next_socket}
    else
      _ -> {:ok, redirect(socket, to: ~p"/controls/courses")}
    end
  end

  defp load_lecturers(course) do
    course_lect = Staff.list_course_lecturers(course)
    possible_lecturers = Staff.possible_lecturers_for(course, limit: 50, offset: 0)
    {course_lect, possible_lecturers}
  end

  def handle_async(:loading, {:ok, result}, socket) do
    Accounts.watch_lecturers()
    Learning.watch_course(socket.assigns.course.id)

    {lecturers, possible_lecturers} = result

    next_socket =
      socket
      |> stream(:assigned, lecturers)
      |> stream(:available, possible_lecturers)
      |> assign(:loading, AsyncResult.ok(socket.assigns.loading, nil))

    {:noreply, next_socket}
  end

  def handle_async(:loading, {:exit, reason}, socket) do
    {:noreply, assign(socket, :loading, AsyncResult.failed(socket.assigns.loading, reason))}
  end

  def render(assigns) do
    ~H"""
    <CommonComponents.navigate_breadcrumbs links={[
      {~p"/controls", gettext("home")},
      {~p"/controls/courses", gettext("courses")},
      {~p"/controls/courses/#{@course.id}", @course.name},
      {~p"/controls/courses/#{@course.id}/assign-lecturer", gettext("assign lecturer")}
    ]} />

    <h1 class="my-5 text-xl font-bold text-secondary">
      <%= gettext("Add lecturer to") %> <%= @course.name %>
    </h1>

    <.async_result assign={@loading}>
      <:loading>
        <.loading_spinner />
      </:loading>
      <:failed>Failed to load lecturers</:failed>

      <h3 class="text-lg font-bold text-secondary mb-3">
        <%= gettext("Assigned") %>
      </h3>
      <ul id="assigned-lecturers" phx-update="stream">
        <li :for={{id, lect} <- @streams.assigned} id={id} class="flex items-center gap-3 mb-3">
          <img
            src={~p"/images/#{lect.profile_image}"}
            height="38"
            width="38"
            class="rounded-full h-[38px] w-[38px] border-4 border-primary-opaque"
          />

          <span class="me-auto"><%= lect.name %></span>

          <CommonComponents.transparent_button
            id={"unassign-lecturer-#{lect.id}"}
            phx-click="unassign-lecturer"
            phx-value-id={lect.id}
            phx-throttle
          >
            <%= gettext("Remove") %>
          </CommonComponents.transparent_button>
        </li>
      </ul>

      <h3 class="text-lg font-bold text-secondary mt-5 mb-3"><%= gettext("Available") %></h3>
      <ul id="available-lecturers" phx-update="stream">
        <li :for={{id, lect} <- @streams.available} id={id} class="flex items-center gap-3 mb-3">
          <img
            src={~p"/images/#{lect.profile_image}"}
            height="38"
            width="38"
            class="rounded-full h-[38px] w-[38px] border-4 border-primary-opaque"
          />

          <span class="me-auto"><%= lect.name %></span>

          <CommonComponents.transparent_button
            id={"assign-lecturer-#{lect.id}"}
            phx-click="assign-lecturer"
            phx-value-id={lect.id}
            phx-throttle
          >
            <%= gettext("Assign") %>
          </CommonComponents.transparent_button>
        </li>
      </ul>
    </.async_result>
    """
  end

  def handle_event("unassign-lecturer", %{"id" => raw_id}, socket) do
    lect =
      raw_id
      |> String.to_integer()
      |> Accounts.get_lecturer!()

    Staff.remove_lecturer_from_course(socket.assigns.course, lect)

    {:noreply, socket}
  end

  def handle_event("assign-lecturer", %{"id" => raw_id}, socket) do
    lect =
      raw_id
      |> String.to_integer()
      |> Accounts.get_lecturer!()

    Staff.add_lecturer_to_course(socket.assigns.course, lect)

    {:noreply, socket}
  end

  def handle_info({:lecturers, :lecturer_registered, lect}, socket),
    do: {:noreply, stream_insert(socket, :available, lect, at: 0)}

  def handle_info({:lecturers, :lecturer_updated, lect}, socket) when lect.enabled == false,
    do: {:noreply, socket |> stream_delete(:available, lect) |> stream_delete(:assigned, lect)}

  def handle_info({:lecturers, :lecturer_updated, _}, socket) do
    {:noreply, socket}
  end

  def handle_info({:course, _, :lecturer_added, lect}, socket) do
    next_socket =
      socket
      |> stream_delete(:available, lect)
      |> stream_insert(:assigned, lect)

    {:noreply, next_socket}
  end

  def handle_info({:course, _, :lecturer_removed, lect}, socket),
    do:
      {:noreply,
       socket |> stream_delete(:assigned, lect) |> stream_insert(:available, lect, at: 0)}

  def handle_info({:course, _, :course_updated, course}, socket),
    do: {:noreply, assign(socket, course: course)}
end
