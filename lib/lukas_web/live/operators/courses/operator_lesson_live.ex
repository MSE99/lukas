defmodule LukasWeb.Operator.LessonLive do
  use LukasWeb, :live_view

  alias Lukas.Learning
  alias Lukas.Learning.Course.Content

  alias LukasWeb.CommonComponents

  def mount(%{"id" => raw_course_id, "lesson_id" => raw_lesson_id}, _session, socket) do
    with {course_id, _} <- Integer.parse(raw_course_id),
         {lesson_id, _} <- Integer.parse(raw_lesson_id),
         {lesson, topics} when lesson != nil <-
           Content.get_lesson_and_topic_names(course_id, lesson_id),
         course = Learning.get_course(course_id) do
      Learning.watch_course(course_id)

      {:ok,
       socket
       |> assign(lesson: lesson)
       |> stream(:topics, topics)
       |> assign(course: course)
       |> allow_upload(:image,
         max_entries: 1,
         accept: ~w(.jpg .jpeg .png .webp .mp4 .webm .pdf .txt .docx .doc .xlsx .xls .rar .zip),
         max_file_size: 120_000_000
       )}
    else
      _ -> {:ok, redirect(socket, to: ~p"/")}
    end
  end

  def handle_params(%{"topic_id" => raw_topic_id}, _, socket)
      when socket.assigns.live_action == :edit_topic do
    with {id, _} <- Integer.parse(raw_topic_id),
         topic when topic != nil <- Content.get_topic(socket.assigns.lesson.id, id) do
      cs = Content.update_topic_changeset(Map.from_struct(topic))
      form = to_form(cs)
      {:noreply, assign(socket, form: form, topic_kind: "#{topic.kind}", topic: topic)}
    else
      _ -> {:noreply, redirect(socket, to: ~p"/")}
    end
  end

  def handle_params(_, _, socket) when socket.assigns.live_action == :new_topic do
    cs = Content.create_topic_changeset(socket.assigns.lesson)
    form = to_form(cs)
    {:noreply, assign(socket, form: form, topic_kind: "text")}
  end

  def handle_params(_, _, socket), do: {:noreply, socket}

  def render(assigns) do
    ~H"""
    <CommonComponents.navigate_breadcrumbs links={[
      {~p"/controls", "home"},
      {~p"/controls/courses", gettext("courses")},
      {~p"/controls/courses/#{@course.id}", @course.name},
      {~p"/controls/courses/#{@course.id}/lessons", "lessons"}
    ]} />

    <h1 class="text-primary text-2xl font-bold mb-8">Lesson <%= @lesson.title %></h1>

    <p class="text-md text-secondary mb-5"><%= @lesson.description %></p>

    <div class="flex justify-end gap-2">
      <.link patch={~p"/controls/courses/#{@lesson.course_id}/lessons/#{@lesson.id}/new-topic"}>
        <.button class="flex items-center gap-3">
          <%= gettext("New video topic") %>
          <.icon name="hero-plus-circle-solid" />
        </.button>
      </.link>
    </div>

    <ul id="topics" phx-update="stream" class="mt-10">
      <li
        :for={{id, topic} <- @streams.topics}
        id={id}
        class="font-bold text-black flex items-center gap-3 my-3"
      >
        <span class="me-auto"><%= topic.title %></span>

        <.link
          :if={topic.kind != :text}
          patch={
            ~p"/controls/courses/#{@lesson.course_id}/lessons/#{@lesson.id}/topics/#{topic.id}/edit-topic"
          }
        >
          <.icon name="hero-pencil" />
        </.link>

        <span id={"delete-topic-#{topic.id}"} phx-click="delete-topic" phx-value-id={topic.id}>
          <.icon name="hero-trash" />
        </span>
      </li>
    </ul>

    <.modal
      :if={@live_action in [:edit_topic, :new_topic]}
      id="new-topic-modal"
      on_cancel={JS.patch(~p"/controls/courses/#{@lesson.course_id}/lessons/#{@lesson.id}")}
      show
    >
      <img
        :if={@live_action == :edit_topic and @topic.kind == :text}
        src={
          ~p"/controls/courses/#{@lesson.course_id}/lessons/#{@lesson.id}/topics/#{@topic.media}/media"
        }
        class="w-full h-auto rounded-xl mb-3"
      />

      <video
        :if={@live_action == :edit_topic and @topic.kind == :video}
        controls
        class="w-full h-auto mb-5 rounded-lg shadow"
      >
        <source src={
          ~p"/controls/courses/#{@lesson.course_id}/lessons/#{@lesson.id}/topics/#{@topic.id}/media"
        } />
      </video>

      <.form
        for={@form}
        phx-change="validate"
        phx-submit={if @live_action == :new_topic, do: "create", else: "update"}
      >
        <.input field={@form[:title]} type="text" label={gettext("Title")} />

        <.input
          field={@form[:kind]}
          type="select"
          label={gettext("Kind")}
          options={Content.topic_kinds()}
          phx-change="update-topic-kind"
        />

        <.input type="textarea" label={gettext("Content")} field={@form[:content]} />

        <div class="my-5">
          <p class="font-bold mb-3">
            <%= gettext("media") %>
          </p>

          <.live_file_input upload={@uploads.image} />
        </div>

        <%= for entry <- @uploads.image.entries do %>
          <progress value={entry.progress} max="100">
            <%= entry.progress %>%
          </progress>

          <%= for err <- upload_errors(@uploads.image, entry) do %>
            <p class="alert alert-danger"><%= error_to_string(err) %></p>
          <% end %>
        <% end %>

        <div class="mt-10 flex justify-end">
          <.button>
            <%= gettext("Create") %>
          </.button>
        </div>
      </.form>
    </.modal>
    """
  end

  def error_to_string(:too_large), do: gettext("Too large")
  def error_to_string(:not_accepted), do: gettext("You have selected an unacceptable file type")

  def handle_event("delete-topic", %{"id" => raw_topic_id}, socket) do
    {id, _} = Integer.parse(raw_topic_id)
    topic = Content.get_topic(socket.assigns.lesson.id, id)
    {:ok, _} = Content.remove_topic(topic)
    {:noreply, socket}
  end

  def handle_event("validate", %{"topic" => params}, socket) do
    cs = Content.validate_topic(socket.assigns.lesson, params)
    form = to_form(cs)
    {:noreply, assign(socket, form: form)}
  end

  def handle_event("update", %{"topic" => params}, socket) do
    case Content.update_topic(socket.assigns.topic, params,
           get_media: fn -> consume_image_upload(socket) end
         ) do
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

  def handle_event("create", %{"topic" => params}, socket) do
    case Content.create_text_topic(socket.assigns.lesson, params,
           get_media: fn -> consume_image_upload(socket) end
         ) do
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

  def handle_event("update-topic-kind", %{"topic" => %{"kind" => kind}}, socket) do
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

  defp consume_image_upload(socket) do
    uploaded_images =
      consume_uploaded_entries(socket, :image, fn %{path: path}, entry ->
        filename = "#{entry.uuid}.#{ext(entry)}"

        dist =
          Path.join([:code.priv_dir(:lukas), "static", "content", "courses", "images", filename])

        File.cp!(path, dist)

        {:ok, filename}
      end)

    default_image =
      case socket.assigns.live_action do
        :edit -> socket.assigns.topic.image
        _ -> Learning.Lesson.Topic.default_image()
      end

    List.first(uploaded_images, default_image)
  end

  defp ext(upload_entry) do
    [ext | _] = MIME.extensions(upload_entry.client_type)
    ext
  end
end
