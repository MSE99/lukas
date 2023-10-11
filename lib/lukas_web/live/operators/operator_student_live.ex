defmodule LukasWeb.Operator.StudentLive do
  use LukasWeb, :live_view

  alias Lukas.Accounts
  alias Lukas.Learning.Course
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
end
