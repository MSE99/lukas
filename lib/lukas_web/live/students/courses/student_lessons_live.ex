defmodule LukasWeb.Students.LessonsLive do
  use LukasWeb, :live_view

  alias Lukas.Learning

  def mount(%{"id" => raw_course_id}, _session, socket) do
    {course_id, _} = Integer.parse(raw_course_id)
    {course, lessons} = Learning.get_progress(socket.assigns.current_user, course_id)
    {:ok, socket |> assign(course: course) |> stream(:lessons, lessons)}
  end

  def handle_params(%{"lesson_id" => raw_lesson_id}, _, socket)
      when socket.assigns.live_action == :lesson do
    lesson_id = String.to_integer(raw_lesson_id)
    lesson = Learning.get_lesson(socket.assigns.course.id, lesson_id)
    {:noreply, assign(socket, lesson: lesson)}
  end

  def handle_params(%{"lesson_id" => raw_lesson_id, "topic_id" => raw_topic_id}, _, socket)
      when socket.assigns.live_action == :topic do
    lesson_id = String.to_integer(raw_lesson_id)
    topic_id = String.to_integer(raw_topic_id)

    topic = Learning.get_topic(lesson_id, topic_id)
    {:noreply, assign(socket, topic: topic)}
  end

  def handle_params(_, _, socket), do: {:noreply, socket}

  def render(assigns) do
    ~H"""
    <h1 class="text-3xl mb-10">Course <%= @course.name %> lessons</h1>

    <ul id="lessons" phx-update="stream" class="list-disc">
      <li :for={{id, lesson} <- @streams.lessons} id={id} class="mb-5">
        <.link patch={~p"/home/courses/#{@course.id}/lessons/#{lesson.id}"} class="font-bold text-xl">
          <%= lesson.title %>
        </.link>

        <ul id={"lesson-#{lesson.id}-topics"} class="pl-5 mt-2">
          <li :for={topic <- lesson.topics} id={"topic-#{topic.id}"}>
            <.link patch={~p"/home/courses/#{@course.id}/lessons/#{lesson.id}/topics/#{topic.id}"}>
              <%= topic.title %> | <%= if topic.completed, do: "finished", else: "unfinished" %>
            </.link>
          </li>
        </ul>
      </li>
    </ul>

    <hr class="mb-5" />

    <div :if={@live_action == :lesson}>
      <h1><%= @lesson.title %></h1>
    </div>

    <div :if={@live_action == :topic}>
      <h1><%= @topic.title %></h1>
      <p><%= @topic.content %></p>
    </div>
    """
  end
end
