defmodule LukasWeb.Operator.LessonLive do
  use LukasWeb, :live_view

  alias Lukas.Learning

  def mount(%{"id" => raw_course_id, "lesson_id" => raw_lesson_id}, _session, socket) do
    with {course_id, _} <- Integer.parse(raw_course_id),
         {lesson_id, _} <- Integer.parse(raw_lesson_id),
         {:ok, lesson, topics} when lesson != nil <-
           Learning.get_lesson_and_topic_names(course_id, lesson_id) do
      Learning.watch_course(course_id)

      {:ok, socket |> assign(lesson: lesson) |> stream(:topics, topics)}
    else
      _ -> {:ok, redirect(socket, to: ~p"/")}
    end
  end

  def handle_params(_, _, socket) when socket.assigns.live_action == :new_topic do
    cs = Learning.create_topic_changeset(socket.assigns.lesson)
    form = to_form(cs)
    {:noreply, assign(socket, form: form, topic_kind: "text")}
  end

  def handle_params(_, _, socket), do: {:noreply, socket}

  def render(assigns) do
    ~H"""
    <.modal
      :if={@live_action == :new_topic}
      id="new-topic-modal"
      on_cancel={JS.patch(~p"/controls/courses/#{@lesson.course_id}/lessons/#{@lesson.id}")}
      show
    >
      <.form for={@form} phx-change="validate" phx-submit="create">
        <.input field={@form[:title]} type="text" label="Title" />
        <.input
          field={@form[:kind]}
          type="select"
          label="Kind"
          options={Learning.topic_kinds()}
          phx-change="update-topic-kind"
        />

        <.input :if={@topic_kind == "text"} type="textarea" label="Content" field={@form[:content]} />
        <.input :if={@topic_kind != "text"} type="text" label="Content" field={@form[:content]} />

        <.button>Create</.button>
      </.form>
    </.modal>

    <h1>Lesson <%= @lesson.title %></h1>

    <p><%= @lesson.description %></p>

    <.link patch={~p"/controls/courses/#{@lesson.course_id}/lessons/#{@lesson.id}/new-topic"}>
      <.button>New topic</.button>
    </.link>

    <ul id="topics" phx-update="stream">
      <li :for={{id, topic} <- @streams.topics} id={id}>
        <%= topic.title %>
      </li>
    </ul>
    """
  end

  def handle_event("validate", %{"topic" => params}, socket) do
    cs = Learning.validate_topic(socket.assigns.lesson, params)
    form = to_form(cs)
    {:noreply, assign(socket, form: form)}
  end

  def handle_event("create", %{"topic" => params}, socket)
      when socket.assigns.topic_kind == "text" do
    case Learning.create_text_topic(socket.assigns.lesson, params) do
      {:error, cs} ->
        {:noreply, assign(socket, form: to_form(cs))}

      {:ok, _} ->
        {:noreply,
         push_patch(socket,
           to:
             ~p"/controls/courses/#{socket.assigns.lesson.course_id}/lessons/#{socket.assigns.lesson.id}"
         )}
    end
  end

  def handle_event("update-topic-kind", %{"kind" => kind}, socket) do
    {:noreply, assign(socket, topic_kind: kind)}
  end

  def handle_info({:course, _, :topic_added, topic}, socket) do
    {:noreply, stream_insert(socket, :topics, topic)}
  end

  def handle_info({:course, _, :topic_updated, topic}, socket) do
    {:noreply, stream_insert(socket, :topics, topic)}
  end

  def handle_info({:course, _, :topic_removed, topic}, socket) do
    {:noreply, stream_delete(socket, :topics, topic)}
  end

  def handle_info({:course, _, :lesson_removed, lesson}, socket)
      when socket.assigns.lesson.id == lesson.id do
    {:noreply, redirect(socket, to: ~p"/controls/courses")}
  end

  def handle_info({:course, _, :lesson_updated, lesson}, socket)
      when socket.assigns.lesson.id == lesson.id do
    {:noreply, assign(socket, lesson: lesson)}
  end

  def handle_info({:course, _, _, _}, socket) do
    {:noreply, socket}
  end
end
