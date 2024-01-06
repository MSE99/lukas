defmodule LukasWeb.Operator.TopicEditorLive do
  use LukasWeb, :live_view

  alias Lukas.Learning
  alias Phoenix.LiveView.AsyncResult

  def mount(params, _, socket) do
    next_socket =
      socket
      |> start_async(:loading, fn ->
        load_content(params)
      end)
      |> assign(:loading, AsyncResult.loading())

    {:ok, next_socket}
  end

  defp load_content(%{
         "id" => raw_course_id,
         "lesson_id" => raw_lesson_id,
         "topic_id" => raw_topic_id
       }) do
    with {topic_id, _} <- Integer.parse(raw_topic_id),
         {course, lesson} <- load_course_and_lesson(raw_course_id, raw_lesson_id),
         topic when topic != nil <- Learning.get_topic_by_id_and_lesson_id(topic_id, lesson.id) do
      {course, lesson, topic}
    else
      _ -> :error
    end
  end

  defp load_content(%{"id" => raw_course_id, "lesson_id" => raw_lesson_id}) do
    load_course_and_lesson(raw_course_id, raw_lesson_id)
  end

  defp load_course_and_lesson(raw_course_id, raw_lesson_id) do
    with {id, _} <- Integer.parse(raw_course_id),
         course when course != nil <- Learning.get_course(id),
         {lesson_id, _} <- Integer.parse(raw_lesson_id),
         lesson when lesson != nil <- Learning.get_lesson_by_id_and_course_id(id, lesson_id) do
      {course, lesson}
    else
      _ -> :error
    end
  end

  def handle_async(:loading, {:exit, _}, socket) do
    {:noreply,
     socket
     |> assign(:loading, AsyncResult.failed(socket.assigns.loading, "Course not found"))
     |> redirect(to: ~p"/controls/courses")}
  end

  def handle_async(:loading, {:ok, :error}, socket) do
    {:noreply,
     socket
     |> assign(:loading, AsyncResult.failed(socket.assigns.loading, "Course not found"))
     |> redirect(to: ~p"/controls/courses")}
  end

  def handle_async(:loading, {:ok, {course, lesson}}, socket) do
    cs = Learning.Course.Content.create_topic_changeset(lesson, %{})
    form = to_form(cs)

    {:noreply,
     socket
     |> assign(:loading, AsyncResult.ok(socket.assigns.loading, course))
     |> assign(:lesson, lesson)
     |> assign(:course, course)
     |> assign(:form, form)
     |> assign(:content, "")}
  end

  def handle_async(:loading, {:ok, {course, lesson, topic}}, socket) do
    cs = Learning.Course.Content.create_topic_changeset(lesson, Map.from_struct(topic))
    form = to_form(cs)

    {:noreply,
     socket
     |> assign(:loading, AsyncResult.ok(socket.assigns.loading, course))
     |> assign(:lesson, lesson)
     |> assign(:course, course)
     |> assign(:form, form)
     |> assign(:topic, topic)
     |> assign(:content, topic.content)}
  end

  def render(assigns) do
    ~H"""
    <.async_result assign={@loading}>
      <:loading>
        <.loading_spinner />
      </:loading>
      <:failed>Failed to load course...</:failed>

      <div id="editor-container" class="mt-10" phx-update="ignore">
        <div id="lesson-editor" phx-update="ignore" phx-hook="Editor" data-original-content={@content}>
        </div>
      </div>

      <.form
        id="topic-form"
        for={@form}
        phx-change="validate"
        phx-submit={if @live_action == :edit_topic, do: "edit", else: "create"}
      >
        <.input field={@form[:title]} type="text" />
        <.button>Save</.button>
      </.form>
    </.async_result>
    """
  end

  def handle_event("create", %{"topic" => topic_attrs}, socket) do
    filled_attrs =
      topic_attrs
      |> Map.put("content", socket.assigns.content)
      |> Map.put("media", Learning.Lesson.Topic.default_image())

    res = Learning.Course.Content.create_text_topic(socket.assigns.lesson, filled_attrs)

    case res do
      {:ok, _} ->
        {:noreply, redirect(socket, to: ~p"/controls/courses/#{socket.assigns.course.id}")}

      {:error, cs} ->
        {:noreply, assign(socket, :form, to_form(cs))}
    end
  end

  def handle_event("edit", %{"topic" => topic_attrs}, socket) do
    filled_attrs =
      topic_attrs
      |> Map.put("content", socket.assigns.content)
      |> Map.put("media", Learning.Lesson.Topic.default_image())

    res = Learning.Course.Content.update_topic(socket.assigns.topic, filled_attrs)

    case res do
      {:ok, _} ->
        {:noreply,
         redirect(socket,
           to:
             ~p"/controls/courses/#{socket.assigns.course.id}/lessons/#{socket.assigns.lesson.id}"
         )}

      {:error, cs} ->
        {:noreply, assign(socket, :form, to_form(cs))}
    end
  end

  def handle_event("validate", %{"topic" => topic_attrs}, socket) do
    filled_attrs =
      topic_attrs
      |> Map.put("content", socket.assigns.content)
      |> Map.put("media", Learning.Lesson.Topic.default_image())

    cs =
      Learning.Course.Content.validate_topic(
        socket.assigns.lesson,
        filled_attrs
      )

    form = to_form(cs)

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("text-editor", %{"text_content" => content}, socket) do
    {:noreply, socket |> assign(:content, content)}
  end
end
