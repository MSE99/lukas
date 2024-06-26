defmodule LukasWeb.Students.StudyLive do
  use LukasWeb, :live_view

  alias Lukas.Learning
  alias Lukas.Learning.Course.Students

  alias LukasWeb.CommonComponents

  def mount(%{"id" => raw_course_id}, _, socket) do
    student = socket.assigns.current_user
    course_id = String.to_integer(raw_course_id)

    Students.watch_progress(student, course_id)

    {course, lessons} = Students.get_progress(student, course_id)
    next = Students.get_next_lesson_or_topic(lessons)

    next_socket =
      socket
      |> assign(course: course)
      |> assign(next: next)
      |> assign(lesson: nil)
      |> assign(topic: nil)
      |> assign(:completed, Students.calculate_progress_percentage(lessons))
      |> stream(:lessons, lessons)

    {:ok, next_socket, layout: {LukasWeb.Layouts, :frameless}}
  end

  def handle_params(%{"lesson_id" => raw_lesson_id, "topic_id" => raw_topic_id}, _, socket) do
    topic_id = String.to_integer(raw_topic_id)
    lesson_id = String.to_integer(raw_lesson_id)

    topic =
      Learning.Course.Content.get_topic_for_student!(
        socket.assigns.current_user,
        socket.assigns.course.id,
        lesson_id,
        topic_id
      )

    {:noreply, assign(socket, topic: topic, lesson: nil)}
  end

  def handle_params(%{"lesson_id" => raw_lesson_id}, _, socket) do
    student = socket.assigns.current_user
    course = socket.assigns.course
    lesson_id = String.to_integer(raw_lesson_id)

    lesson = Learning.Course.Content.get_lesson_for_student!(student, course.id, lesson_id)

    {:noreply, assign(socket, topic: nil, lesson: lesson)}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, patch_to_next(socket)}
  end

  def patch_to_next(socket, opts \\ []) do
    patch_home? = Keyword.get(opts, :patch_home?, false)

    case socket.assigns.next do
      :course_home ->
        if patch_home? do
          socket
          |> push_patch(to: ~p"/home/courses/#{socket.assigns.course.id}/study")
          |> assign(topic: nil)
          |> assign(lesson: nil)
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
    <div class="w-full min-h-screen flex flex-col lg:flex-row">
      <div class="w-full pt-10 px-2 md:max-h-screen md:overflow-y-auto">
        <div :if={@lesson} class="max-w-2xl mx-auto">
          <CommonComponents.course_banner image_src={
            ~p"/home/courses/#{@lesson.course_id}/lessons/#{@lesson.id}/image"
          } />

          <.main_title>
            <%= @lesson.title %>
          </.main_title>

          <.paragraph class="mb-10"><%= @lesson.description %></.paragraph>

          <div class="flex justify-end mt-10">
            <.button
              :if={@lesson.progressed == false}
              phx-click="progress-lesson"
              class="px-8 py-2 me-1 mb-5"
            >
              <%= gettext("next") %>
            </.button>
          </div>
        </div>

        <div :if={@topic} class="max-w-2xl mx-auto">
          <.main_title>
            <%= @topic.title %>
          </.main_title>

          <video :if={@topic.kind == :video} controls class="w-full h-auto mb-5 rounded-lg shadow">
            <source src={
              ~p"/home/courses/#{@course.id}/lessons/#{@topic.lesson_id}/topics/#{@topic.id}/media"
            } />
          </video>

          <div :if={@topic.kind == :text} class="tiny-mce-content">
            <%= {:safe, @topic.content} %>
          </div>

          <.paragraph :if={@topic.kind == :file} class="mb-10">
            <%= @topic.content %>
          </.paragraph>

          <a
            :if={@topic.kind == :file}
            href={
              ~p"/home/courses/#{@course.id}/lessons/#{@topic.lesson_id}/topics/#{@topic.id}/media"
            }
            target="_blank"
            class="block mt-5"
          >
            <.button class="flex justify-center items-center gap-3">
              <.icon name="hero-arrow-down" />
              <%= gettext("Download file") %>
            </.button>
          </a>

          <div class="flex justify-end mt-10 mb-10">
            <.button
              :if={@topic.progressed == false}
              phx-click="progress-topic"
              class="px-8 py-2 me-1"
            >
              <%= gettext("next") %>
            </.button>
          </div>
        </div>

        <div :if={@topic == nil && @lesson == nil}>
          <CommonComponents.course_banner image_src={~p"/home/courses/#{@course.id}/banner"} />

          <div class="mt-10 text-secondary px-2 pb-5 max-w-2xl mx-auto">
            <div class="flex justify-end">
              <.button id="reset-button" phx-click="reset-progress" class="me-1">
                <%= gettext("reset progress") %>
              </.button>
            </div>
          </div>
        </div>
      </div>

      <div class="w-full lg:max-w-sm p-10 bg-gray-200 min-h-screen">
        <div class="flex flex-col gap-3 mb-3 justify-start">
          <h1 class="text-2xl font-bold text-secondary"><%= @course.name %></h1>

          <CommonComponents.navigate_breadcrumbs links={[
            {~p"/home", gettext("home")},
            {~p"/home/courses", gettext("courses")},
            {~p"/home/courses/#{@course.id}", @course.name},
            {~p"/home/courses/#{@course.id}/study", gettext("study")}
          ]} />

          <p class="font-bold text-primary text-sm">
            completed <%= :erlang.float_to_binary(@completed, decimals: 1) %>%
          </p>
        </div>

        <ul id="lessons" phx-update="stream" class="text-secondary">
          <li :for={{id, lesson} <- @streams.lessons} id={id} class="mb-5">
            <.link
              patch={~p"/home/courses/#{@course.id}/study?lesson_id=#{lesson.id}"}
              class="font-bold text-xl"
            >
              <%= lesson.title %> <%= if Enum.all?(lesson.topics, fn topic -> topic.progressed end) and
                                           lesson.progressed,
                                         do: "✓",
                                         else: "" %>
            </.link>

            <ul id={"lesson-#{lesson.id}-topics"} class="ps-5">
              <li :for={topic <- lesson.topics} class="my-1 text-md">
                <.link patch={
                  ~p"/home/courses/#{@course.id}/study?lesson_id=#{topic.lesson_id}&topic_id=#{topic.id}"
                }>
                  <%= topic.title %> <%= if topic.progressed, do: "✓", else: "" %>
                </.link>
              </li>
            </ul>
          </li>
        </ul>
      </div>
    </div>
    """
  end

  def handle_info({:progress, _, {course, lessons}}, socket) do
    next = Students.get_next_lesson_or_topic(lessons)

    next_socket =
      socket
      |> assign(course: course)
      |> assign(next: next)
      |> stream(:lessons, lessons, reset: true)
      |> assign(:completed, Students.calculate_progress_percentage(lessons))
      |> patch_to_next(patch_home?: true)

    {:noreply, next_socket}
  end

  def handle_event("progress-lesson", _, socket) do
    lesson = socket.assigns.lesson
    student = socket.assigns.current_user

    Students.progress_through_lesson(student, lesson)

    {:noreply, socket}
  end

  def handle_event("progress-topic", _, socket) do
    topic = socket.assigns.topic
    student = socket.assigns.current_user

    Students.progress_through_topic(student, topic)

    {:noreply, socket}
  end

  def handle_event("reset-progress", _, socket) do
    Students.reset_progress(socket.assigns.course, socket.assigns.current_user)
    {:noreply, socket}
  end

  defp main_title(assigns) do
    ~H"""
    <h1 class="text-secondary text-3xl lg:text-center font-bold mb-5">
      <%= render_slot(@inner_block) %>
    </h1>
    """
  end

  defp paragraph(assigns) do
    ~H"""
    <p class="text-secondary text-xl">
      <%= render_slot(@inner_block) %>
    </p>
    """
  end
end
