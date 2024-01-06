defmodule LukasWeb.Operator.TopicEditorLive do
  use LukasWeb, :live_view

  alias Lukas.Learning
  alias Phoenix.LiveView.AsyncResult

  def mount(%{"id" => raw_course_id, "lesson_id" => raw_lesson_id}, _, socket) do
    next_socket =
      socket
      |> start_async(:loading, fn -> load_course(raw_course_id, raw_lesson_id) end)
      |> assign(:loading, AsyncResult.loading())

    {:ok, next_socket}
  end

  defp load_course(raw_id, raw_lesson_id) do
    with {id, _} <- Integer.parse(raw_id),
         course when course != nil <- Learning.get_course(id),
         {lesson_id, _} <- Integer.parse(raw_lesson_id),
         lesson when lesson != nil <- Learning.get_lesson_by_id_lesson_id(id, lesson_id) do
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

  def render(assigns) do
    ~H"""
    <.async_result assign={@loading}>
      <:loading>
        <.loading_spinner />
      </:loading>
      <:failed>Failed to load course...</:failed>

      <div id="editor-container" class="mt-10" phx-update="ignore">
        <div id="lesson-editor" phx-update="ignore" phx-hook="Editor"></div>
      </div>

      <.form id="topic-form" for={@form} phx-change="validate" phx-submit="create">
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
