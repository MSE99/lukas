defmodule LukasWeb.Operator.CourseLessonsLive do
  use LukasWeb, :live_view

  alias Lukas.Learning

  alias LukasWeb.CommonComponents
  alias Phoenix.LiveView.AsyncResult

  def mount(params, _session, socket) do
    {:ok,
     socket
     |> stream_configure(:lessons, [])
     |> assign(:loading, AsyncResult.loading())
     |> start_async(:loading, fn -> load_course_with_lessons(params) end)
     |> assign(:show_form_modal, false)
     |> allow_upload(:image, max_entries: 1, accept: ~w(.jpg .jpeg .png))}
  end

  defp load_course_with_lessons(%{"id" => raw_id}) do
    with {id, _} <- Integer.parse(raw_id), course when course != nil <- Learning.get_course(id) do
      lessons = Learning.get_lessons(course)
      {course, lessons}
    else
      _ -> :error
    end
  end

  def handle_async(:loading, {:ok, {course, lessons}}, socket) do
    Learning.watch_course(course)

    form = Learning.Course.Content.create_lesson_changeset(course) |> to_form()

    next_socket =
      socket
      |> assign(:loading, AsyncResult.ok(socket.assigns.loading, nil))
      |> assign(:course, course)
      |> assign(:form, form)
      |> assign(:lesson, nil)
      |> stream(:lessons, lessons)

    {:noreply, next_socket}
  end

  def handle_async(:loading, {:ok, :error}, socket) do
    {:noreply, redirect(socket, to: ~p"/controls/courses")}
  end

  def handle_async(:loading, {:exit, reason}, socket) do
    next_socket =
      socket
      |> assign(:loading, AsyncResult.failed(socket.assigns.loading, reason))

    {:noreply, next_socket}
  end

  def render(assigns) do
    ~H"""
    <.async_result assign={@loading}>
      <:loading><.loading_spinner /></:loading>
      <:failed>Failed...</:failed>

      <CommonComponents.navigate_breadcrumbs links={[
        {~p"/controls", gettext("home")},
        {~p"/controls/courses", gettext("courses")},
        {~p"/controls/courses/#{@course.id}", @course.name},
        {~p"/controls/courses/#{@course.id}/lessons", gettext("lessons")}
      ]} />

      <div class="flex justify-end">
        <.button id="new-button" phx-click="prep-create" class="px-5 flex justify-center items-center">
          <%= gettext("Add lesson") %> <.icon name="hero-plus-circle-solid ms-2" />
        </.button>
      </div>

      <ul id="lessons" phx-update="stream" class="mt-10">
        <li :for={{id, lesson} <- @streams.lessons} id={id} class="flex items-center gap-2">
          <.link navigate={~p"/controls/courses/#{@course.id}/lessons/#{lesson.id}"}>
            <strong class="text-lg underline lg:no-underline hover:underline">
              <%= lesson.title %>
            </strong>
          </.link>

          <span
            id={"lessons-#{lesson.id}-edit"}
            phx-click={
              JS.push("prep-edit", value: %{id: lesson.id}, page_loading: true)
              |> show_modal("form-modal")
            }
            class="ms-auto hover:cursor-pointer"
          >
            <.icon name="hero-pencil-solid text-secondary hover:text-blue-300" />
          </span>

          <span id={"lessons-#{lesson.id}-delete"} phx-click="delete" phx-value-id={lesson.id}>
            <.icon name="hero-trash-solid text-secondary hover:text-red-500 hover:cursor-pointer" />
          </span>
        </li>
      </ul>

      <.modal :if={@show_form_modal} id="form-modal" on_cancel={JS.push("clear")} show>
        <img :if={@lesson} src={~p"/images/#{@lesson.image}"} />

        <.form for={@form} phx-change="validate" phx-submit={if @lesson, do: "edit", else: "create"}>
          <.input type="text" label={gettext("Title")} field={@form[:title]} />
          <.input type="textarea" label={gettext("Description")} field={@form[:description]} />

          <.live_file_input upload={@uploads.image} />

          <%= for entry <- @uploads.image.entries do %>
            <progress value={entry.progress} max="100">
              <%= entry.progress %>%
            </progress>

            <%= for err <- upload_errors(@uploads.image, entry) do %>
              <p class="alert alert-danger"><%= error_to_string(err) %></p>
            <% end %>
          <% end %>

          <div class="mt-5 flex justify-end">
            <.button class="px-8">
              <%= gettext("Create") %>
            </.button>
          </div>
        </.form>
      </.modal>
    </.async_result>
    """
  end

  def error_to_string(:too_large), do: gettext("Too large")
  def error_to_string(:not_accepted), do: gettext("You have selected an unacceptable file type")

  def handle_event("clear", _, socket) do
    form = Learning.Course.Content.create_lesson_changeset(socket.assigns.course) |> to_form()

    {:noreply,
     socket |> assign(:lesson, nil) |> assign(:form, form) |> assign(:show_form_modal, false)}
  end

  def handle_event("prep-create", _, socket) do
    {:noreply, assign(socket, :show_form_modal, true)}
  end

  def handle_event("prep-edit", %{"id" => id}, socket) do
    lesson = Learning.Course.Content.get_lesson!(socket.assigns.course.id, id)
    cs = Learning.Course.Content.edit_lesson_changeset(lesson, %{})
    form = to_form(cs)

    {:noreply,
     socket |> assign(:lesson, lesson) |> assign(form: form) |> assign(:show_form_modal, true)}
  end

  def handle_event("edit", %{"lesson" => params}, socket) do
    case Learning.Course.Content.update_lesson(socket.assigns.lesson, params) do
      {:ok, lesson} ->
        next_form =
          Learning.Course.Content.create_lesson_changeset(socket.assigns.course) |> to_form()

        {:noreply,
         socket
         |> stream_insert(:lessons, lesson)
         |> assign(:lesson, nil)
         |> assign(:form, next_form)
         |> assign(:show_form_modal, false)}

      {:error, cs} ->
        {:noreply, assign(socket, form: to_form(cs))}
    end
  end

  def handle_event("create", %{"lesson" => params}, socket) do
    case Learning.Course.Content.create_lesson(socket.assigns.course, params,
           get_image: fn -> consume_image_upload(socket) end
         ) do
      {:ok, lesson} ->
        next_form =
          Learning.Course.Content.create_lesson_changeset(socket.assigns.course) |> to_form()

        {:noreply,
         stream_insert(socket, :lessons, lesson)
         |> assign(:show_form_modal, false)
         |> assign(:form, next_form)}

      {:error, cs} ->
        {:noreply, assign(socket, form: to_form(cs))}
    end
  end

  def handle_event("validate", %{"lesson" => params}, socket) do
    cs = Learning.Course.Content.validate_lesson(socket.assigns.course, params)
    form = to_form(cs)
    {:noreply, assign(socket, form: form)}
  end

  # TODO: Replace this insecure code, attacker can use
  # the id parameter to delete any lesson on the system. 
  def handle_event("delete", %{"id" => raw_id}, socket) do
    raw_id
    |> String.to_integer()
    |> Learning.Course.Content.remove_lesson()

    {:noreply, socket |> stream_delete_by_dom_id(:lessons, "lessons-#{raw_id}")}
  end

  defp consume_image_upload(socket) do
    uploaded_images =
      consume_uploaded_entries(socket, :image, fn %{path: path}, entry ->
        filename = "#{entry.uuid}.#{ext(entry)}"
        dist = Path.join([:code.priv_dir(:lukas), "static", "images", filename])

        File.cp!(path, dist)

        {:ok, filename}
      end)

    default_image =
      case socket.assigns.live_action do
        :edit -> socket.assigns.lesson.image
        _ -> Learning.Lesson.default_image()
      end

    List.first(uploaded_images, default_image)
  end

  defp ext(upload_entry) do
    [ext | _] = MIME.extensions(upload_entry.client_type)
    ext
  end

  def handle_info({:course, _, :lesson_added, lesson}, socket) do
    {:noreply, stream_insert(socket, :lessons, lesson)}
  end

  def handle_info({:course, _, :lesson_deleted, lesson}, socket) do
    {:noreply, stream_delete(socket, :lessons, lesson)}
  end

  def handle_info({:course, _, :lesson_updated, lesson}, socket) do
    {:noreply, stream_insert(socket, :lessons, lesson)}
  end

  def handle_info({:course, _, :course_updated, course}, socket) do
    {:noreply, assign(socket, :course, course)}
  end

  def handle_info({:course, _, _, _}, socket), do: {:noreply, socket}
end
