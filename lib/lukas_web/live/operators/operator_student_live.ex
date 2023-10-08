defmodule LukasWeb.Operator.StudentLive do
  use LukasWeb, :live_view

  alias Lukas.Accounts
  alias Lukas.Learning.Course

  def mount(%{"id" => raw_student_id}, _, socket) do
    with {id, _} <- Integer.parse(raw_student_id),
         student when student != nil <- Accounts.get_student(id),
         courses <- Course.Students.list_student_courses(student) do
      {:ok, socket |> assign(:student, student) |> stream(:courses, courses)}
    else
      _ -> {:ok, redirect(socket, to: ~p"/controls/students")}
    end
  end

  def render(assigns) do
    ~H"""
    <h1><%= @student.name %></h1>

    <ul id="courses" phx-update="stream">
      <li :for={{id, course} <- @streams.courses} id={id}>
        <%= course.name %>
      </li>
    </ul>
    """
  end
end
