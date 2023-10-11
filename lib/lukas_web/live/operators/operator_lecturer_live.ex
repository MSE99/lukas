defmodule LukasWeb.Operator.LecturerLive do
  use LukasWeb, :live_view

  alias Lukas.Accounts
  alias Lukas.Learning.Course.Staff
  alias Phoenix.LiveView.AsyncResult

  def mount(%{"id" => raw_id}, _, socket) do
    with {id, _} <- Integer.parse(raw_id), lect when lect != nil <- Accounts.get_lecturer(id) do
      Accounts.watch_lecturer(lect)

      next_socket =
        socket
        |> assign(:lecturer, lect)
        |> assign(:loading, AsyncResult.loading())
        |> start_async(:loading, fn -> Staff.list_lecturer_courses(id) end)
        |> stream_configure(:courses, [])

      {:ok, next_socket}
    else
      _ -> {:ok, redirect(socket, to: ~p"/controls/lecturers")}
    end
  end

  def handle_async(:loading, {:ok, courses}, socket) do
    Staff.watch_staff_status(socket.assigns.lecturer.id)

    next_socket =
      socket
      |> stream(:courses, courses)
      |> assign(:loading, AsyncResult.ok(socket.assigns.loading, nil))

    {:noreply, next_socket}
  end

  def handle_async(:loading, {:exit, reason}, socket) do
    {:noreply, assign(socket, loading: AsyncResult.failed(socket.assigns.loading, reason))}
  end

  def render(assigns) do
    ~H"""
    <h1><%= @lecturer.name %></h1>

    <.link navigate={~p"/controls/lecturers"}>
      Go back
    </.link>

    <.button :if={@lecturer.enabled} id="disable-lecturer" phx-click="disable" phx-throttle>
      Disable
    </.button>

    <.button :if={@lecturer.enabled == false} id="enable-lecturer" phx-click="enable" phx-throttle>
      Enable
    </.button>

    <.async_result assign={@loading}>
      <:loading>Loading courses...</:loading>
      <:failed>Failed...</:failed>

      <ul id="courses" phx-update="stream">
        <li :for={{id, course} <- @streams.courses} id={id}>
          <%= course.name %>
        </li>
      </ul>
    </.async_result>
    """
  end

  def handle_event("disable", _, socket) do
    {:ok, next_lect} =
      socket.assigns.lecturer
      |> Accounts.disable_user()

    {:noreply, assign(socket, :lecturer, next_lect)}
  end

  def handle_event("enable", _, socket) do
    {:ok, next_lect} =
      socket.assigns.lecturer
      |> Accounts.enable_user()

    {:noreply, assign(socket, :lecturer, next_lect)}
  end

  def handle_info({:lecturer, _, :lecturer_updated, lect}, socket) do
    {:noreply, assign(socket, :lecturer, lect)}
  end

  def handle_info({:staff_status, :added_to_course, course}, socket) do
    {:noreply, stream_insert(socket, :courses, course)}
  end
end
