defmodule LukasWeb.Operator.LessonLive do
  use LukasWeb, :live_view

  alias Lukas.Learning

  def mount(%{"id" => raw_course_id, "lesson_id" => raw_lesson_id}, _session, socket) do
    with {course_id, _} <- Integer.parse(raw_course_id),
         {lesson_id, _} <- Integer.parse(raw_lesson_id),
         {:ok, lesson, topics} when lesson != nil <-
           Learning.get_lesson_and_topic_names(course_id, lesson_id) do
      {:ok, socket |> assign(lesson: lesson) |> stream(:topics, topics)}
    else
      _ -> {:ok, redirect(socket, to: ~p"/")}
    end
  end

  def render(assigns) do
    ~H"""
    <h1>Lesson <%= @lesson.title %></h1>

    <p><%= @lesson.description %></p>

    <ul id="topics" phx-update="stream">
      <li :for={{id, topic} <- @streams.topics} id={id}>
        <%= topic.title %>
      </li>
    </ul>
    """
  end
end
