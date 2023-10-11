defmodule LukasWeb.Operator.StudentLive do
  use LukasWeb, :live_view

  alias Lukas.Accounts
  alias Lukas.Learning.Course
  alias Lukas.Learning.Course.Students
  alias Phoenix.LiveView.AsyncResult

  def mount(%{"id" => raw_student_id}, _, socket) do
    with {id, _} <- Integer.parse(raw_student_id),
         student when student != nil <- Accounts.get_student(id) do
      next_socket =
        socket
        |> stream_configure(:courses, [])
        |> assign(:student, student)
        |> assign(:loading, AsyncResult.loading())
        |> start_async(:loading, fn -> Course.Students.list_student_courses(student) end)

      {:ok, next_socket}
    else
      _ -> {:ok, redirect(socket, to: ~p"/controls/students")}
    end
  end

  def handle_async(:loading, {:ok, courses}, socket) do
    Students.watch_student_enrollments(socket.assigns.student)
    Accounts.watch_student(socket.assigns.student)

    next_socket =
      socket
      |> assign(:loading, AsyncResult.ok(socket.assigns.loading, nil))
      |> stream(:courses, courses)

    {:noreply, next_socket}
  end

  def handle_async(:loading, {:exit, reason}, socket) do
    next_socket =
      socket
      |> assign(:loading, AsyncResult.failed(socket.assigns.loading, reason))

    {:noreply, next_socket}
  end

  def render(assigns) do
    ~H"""
    <h1><%= @student.name %></h1>

    <.button :if={@student.enabled} id="disable-button" phx-click="disable-student" phx-throttle>
      Disabled
    </.button>
    <.button :if={!@student.enabled} id="enable-button" phx-click="enable-student" phx-throttle>
      Enable
    </.button>

    <.async_result assign={@loading}>
      <:loading>Loading...</:loading>
      <:failed>Failed...</:failed>

      <ul id="courses" phx-update="stream">
        <li :for={{id, course} <- @streams.courses} id={id}>
          <%= course.name %>
        </li>
      </ul>
    </.async_result>
    """
  end

  def handle_event("disable-student", _, socket) do
    {:ok, student} = Accounts.disable_user(socket.assigns.student)
    {:noreply, socket |> assign(student: student)}
  end

  def handle_event("enable-student", _, socket) do
    {:ok, student} = Accounts.enable_user(socket.assigns.student)
    {:noreply, socket |> assign(student: student)}
  end

  def handle_info({:student, _, :student_updated, student}, socket) do
    {:noreply, assign(socket, student: student)}
  end

  def handle_info({:enrollments, :enrolled, course}, socket) do
    {:noreply, stream_insert(socket, :courses, course)}
  end
end
