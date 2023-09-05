defmodule LukasWeb.Students.StudyLive do
  use LukasWeb, :live_view

  alias Lukas.Learning

  def mount(%{"id" => raw_course_id}, _, socket) do
    student = socket.assigns.current_user
    course_id = String.to_integer(raw_course_id)

    Learning.watch_progress(student, course_id)

    {course, lessons} = Learning.get_progress(student, course_id)
    next = Learning.get_next_lesson_or_topic(lessons)

    next_socket =
      socket
      |> assign(course: course)
      |> assign(next: next)
      |> assign(lesson: nil)
      |> assign(topic: nil)
      |> stream(:lessons, lessons)

    {:ok, next_socket}
  end

  def handle_params(%{"lesson_id" => raw_lesson_id, "topic_id" => raw_topic_id}, _, socket) do
    topic_id = String.to_integer(raw_topic_id)
    lesson_id = String.to_integer(raw_lesson_id)

    topic = Learning.get_topic!(socket.assigns.course.id, lesson_id, topic_id)

    {:noreply, assign(socket, topic: topic, lesson: nil)}
  end

  def handle_params(%{"lesson_id" => raw_lesson_id}, _, socket) do
    lesson_id = String.to_integer(raw_lesson_id)
    lesson = Learning.get_lesson!(socket.assigns.course.id, lesson_id)

    {:noreply, assign(socket, topic: nil, lesson: lesson)}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, patch_to_next(socket)}
  end

  def patch_to_next(socket, patch_home? \\ false) do
    case socket.assigns.next do
      :course_home ->
        if patch_home? do
          socket |> push_patch(to: ~p"/home/courses/#{socket.assigns.course.id}/study")
        else
          socket
        end

      {:lesson, lesson} ->
        push_patch(
          socket,
          to: ~p"/home/courses/#{socket.assigns.course.id}/study?lesson_id=#{lesson.id}"
        )

      {:topic, topic} ->
        push_patch(
          socket,
          to:
            ~p"/home/courses/#{socket.assigns.course.id}/study?lesson_id=#{topic.lesson_id}&topic_id=#{topic.id}"
        )
    end
  end

  def render(assigns) do
    ~H"""
    <h1 class="text-3xl mb-10"><%= @course.name %></h1>

    <ul id="lessons" phx-update="stream" class="list-disc mb-10">
      <li :for={{id, lesson} <- @streams.lessons} id={id} class="mb-5">
        <.link patch={~p"/home/courses/#{@course.id}/study?lesson_id=#{lesson.id}"}>
          <%= lesson.title %> <%= if lesson.progressed, do: "(done)", else: "" %>
        </.link>

        <ul id={"lesson-#{lesson.id}-topics"} class="pl-3">
          <li :for={topic <- lesson.topics} class="my-1">
            <.link patch={
              ~p"/home/courses/#{@course.id}/study?lesson_id=#{topic.lesson_id}&topic_id=#{topic.id}"
            }>
              <%= topic.title %> <%= if topic.progressed, do: "(done)", else: "" %>
            </.link>
          </li>
        </ul>
      </li>
    </ul>

    <hr class="my-5" />

    <div :if={@lesson}>
      <h1 class="text-xl font-bold mb-5"><%= @lesson.title %></h1>
      <p class="mb-10"><%= @lesson.description %></p>

      <.button phx-click="progress-lesson">next</.button>
    </div>

    <div :if={@topic}>
      <h1 class="text-xl font-bold mb-5"><%= @topic.title %></h1>
      <p class="mb-10"><%= @topic.content %></p>
      <.button phx-click="progress-topic">next</.button>
    </div>
    """
  end

  def handle_info({:progress, _, {course, lessons}}, socket) do
    next = Learning.get_next_lesson_or_topic(lessons)

    next_socket =
      socket
      |> assign(course: course)
      |> assign(next: next)
      |> stream(:lessons, lessons, reset: true)
      |> patch_to_next(true)

    {:noreply, next_socket}
  end

  def handle_event("progress-lesson", _, socket) do
    lesson = socket.assigns.lesson
    student = socket.assigns.current_user

    Learning.progress_through_lesson(student, lesson)

    {:noreply, socket}
  end

  def handle_event("progress-topic", _, socket) do
    topic = socket.assigns.topic
    student = socket.assigns.current_user

    Learning.progress_through_topic(student, topic)

    {:noreply, socket}
  end
end
