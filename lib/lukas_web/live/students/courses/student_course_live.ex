defmodule LukasWeb.Students.CourseLive do
  use LukasWeb, :live_view

  alias Lukas.Learning

  def mount(%{"id" => raw_course_id}, _session, socket) do
    with {id, _} <- Integer.parse(raw_course_id),
         {course, lect, tags, is_enrolled} when course != nil <-
           Learning.get_course_for_student(id, socket.assigns.current_user) do
      Learning.watch_course(id)

      {:ok,
       socket
       |> assign(course: course)
       |> assign(is_enrolled: is_enrolled)
       |> stream(:lecturers, lect)
       |> stream(:tags, tags)}
    else
      _ -> {:ok, redirect(socket, to: ~p"/home/courses")}
    end
  end

  def handle_params(_, _, socket), do: {:noreply, socket}

  def render(assigns) do
    ~H"""
    <h1>Course <%= @course.name %></h1>

    <.button :if={!@is_enrolled} id="enroll-button" phx-click="enroll">
      Enroll
    </.button>

    <.link :if={@is_enrolled} navigate={~p"/home/courses/#{@course.id}/lessons"}>
      <.button>
        Lessons
      </.button>
    </.link>


    <ul id="lecturers" phx-update="stream">
      <li :for={{id, lecturer} <- @streams.lecturers} id={id}>
        <%= lecturer.name %>
      </li>
    </ul>

    <ul id="tags" phx-update="stream">
      <li :for={{id, tag} <- @streams.tags} id={id}>
        <%= tag.name %>
      </li>
    </ul>
    """
  end

  def handle_event("enroll", _params, socket) do
    {:ok, _} = Learning.enroll_student(socket.assigns.course, socket.assigns.current_user)
    {:noreply, push_patch(socket, to: ~p"/home/courses/#{socket.assigns.course.id}")}
  end

  def handle_info({:course, _, :course_updated, course}, socket) do
    {:noreply, assign(socket, course: course)}
  end

  def handle_info({:course, _, :lecturer_added, lecturer}, socket) do
    {:noreply, stream_insert(socket, :lecturers, lecturer)}
  end

  def handle_info({:course, _, :lecturer_removed, lecturer}, socket) do
    {:noreply, stream_delete(socket, :lecturers, lecturer)}
  end

  def handle_info({:course, _, :course_tagged, tag}, socket) do
    {:noreply, stream_insert(socket, :tags, tag)}
  end

  def handle_info({:course, _, :course_untagged, tag}, socket) do
    {:noreply, stream_delete(socket, :tags, tag)}
  end

  def handle_info({:course, _, :student_enrolled, student}, socket)
      when student.id == socket.assigns.current_user.id do
    {:noreply, assign(socket, is_enrolled: true)}
  end

  def handle_info({:course, _, _, _}, socket), do: {:noreply, socket}
end
