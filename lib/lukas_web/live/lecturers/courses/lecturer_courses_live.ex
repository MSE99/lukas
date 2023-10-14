defmodule LukasWeb.Lecturer.CoursesLive do
  use LukasWeb, :live_view

  alias Lukas.{Learning, Categories}
  alias Lukas.Learning.Course

  def mount(_, _, socket) do
    lecturer = socket.assigns.current_user

    Learning.Course.Staff.watch_staff_status(lecturer.id)

    courses = Learning.Course.Staff.list_lecturer_courses(lecturer.id)

    {:ok,
     socket
     |> stream(:courses, courses)
     |> allow_upload(:banner_image, accept: ~w(.jpg .jpeg .png .webp))}
  end

  def handle_params(_, _, socket) when socket.assigns.live_action == :new do
    cs = Learning.create_course_changeset()
    form = to_form(cs)
    tags = Categories.list_tags()
    {:noreply, assign(socket, form: form, chosen_tag_ids: []) |> stream(:tags, tags, reset: true)}
  end

  def handle_params(%{"id" => raw_id}, _, socket) when socket.assigns.live_action == :edit do
    {course, course_tags} =
      raw_id
      |> String.to_integer()
      |> Learning.get_course_and_tags_for_lecturer(socket.assigns.current_user.id)

    tags = Categories.list_tags()
    form = to_form(Learning.update_course_changeset(course, %{}))

    next_socket =
      socket
      |> assign(course: course)
      |> assign(form: form)
      |> assign(chosen_tag_ids: Enum.map(course_tags, & &1.id))
      |> stream(:tags, tags, reset: true)

    {:noreply, next_socket}
  end

  def handle_params(_, _, socket) do
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <h1>My courses</h1>

    <.link patch={~p"/tutor/my-courses/new"}>
      <.button>New Course</.button>
    </.link>

    <ul id="courses" phx-update="stream">
      <li :for={{id, course} <- @streams.courses} id={id}>
        <.link navigate={~p"/tutor/my-courses/#{course.id}"}><%= course.name %></.link>
      </li>
    </ul>

    <.modal
      :if={@live_action in [:new, :edit]}
      id="new-course-modal"
      on_cancel={JS.patch(~p"/tutor/my-courses")}
      show
    >
      <.form
        for={@form}
        phx-change="validate"
        phx-submit={if @live_action == :edit, do: "edit", else: "create"}
      >
        <.input field={@form[:name]} type="text" label="Name" phx-debounce="blur" />
        <.input field={@form[:price]} type="number" label="Name" phx-debounce="blur" />
        <.input field={@form[:description]} type="textarea" label="Description" phx-debounce="blur" />

        <div id="tags" phx-update="stream">
          <span
            :for={{id, tag} <- @streams.tags}
            id={id}
            phx-click="toggle-tag"
            phx-value-id={tag.id}
            class={[
              tag.id in @chosen_tag_ids && "font-bold blue"
            ]}
            phx-throttle
          >
            <%= tag.name %>
          </span>
        </div>

        <.live_file_input upload={@uploads.banner_image} />

        <%= for entry <- @uploads.banner_image.entries do %>
          <progress value={entry.progress} max="100"></progress>

          <%= for err <- upload_errors(@uploads.banner_image, entry) do %>
            <p class="alert alert-danger"><%= error_to_string(err) %></p>
          <% end %>
        <% end %>

        <.button>Create</.button>
      </.form>
    </.modal>
    """
  end

  def error_to_string(:too_large), do: "Too large"
  def error_to_string(:not_accepted), do: "You have selected an unacceptable file type"

  def handle_event("toggle-tag", %{"id" => raw_id}, socket) do
    id = String.to_integer(raw_id)
    tag = Categories.get_tag!(id)
    chosen_tag_ids = socket.assigns.chosen_tag_ids

    if Enum.find(chosen_tag_ids, nil, fn other_id -> other_id == id end) do
      next_socket =
        socket
        |> assign(chosen_tag_ids: Enum.filter(chosen_tag_ids, fn other_id -> other_id != id end))
        |> stream_insert(:tags, tag)

      {:noreply, next_socket}
    else
      {:noreply,
       socket |> assign(chosen_tag_ids: [id | chosen_tag_ids]) |> stream_insert(:tags, tag)}
    end
  end

  def handle_event("validate", %{"course" => params}, socket) do
    cs = Learning.validate_course(params)
    form = to_form(cs)
    {:noreply, socket |> assign(form: form)}
  end

  def handle_event("create", %{"course" => params}, socket) do
    send_course_created_alert = fn course ->
      Learning.Course.Staff.emit_course_created_by_lecturer(
        course,
        socket.assigns.current_user
      )

      nil
    end

    result =
      Learning.create_course_by_lecturer(
        params,
        socket.assigns.chosen_tag_ids,
        socket.assigns.current_user,
        side_effect: send_course_created_alert,
        get_banner_image_path: fn -> consume_banner_image_upload(socket) end
      )

    case result do
      {:ok, course} ->
        {:noreply,
         socket
         |> stream_insert(:courses, course)
         |> assign(:tags, nil)
         |> push_patch(to: ~p"/tutor/my-courses")}

      {:error, cs} ->
        {:noreply, assign(socket, form: to_form(cs))}
    end
  end

  def handle_event("edit", %{"course" => attrs}, socket) do
    opts = [
      get_banner_image_path: fn -> consume_banner_image_upload(socket) end,
      tag_ids: socket.assigns.chosen_tag_ids
    ]

    case Learning.update_course(socket.assigns.course, attrs, opts) do
      {:ok, course} ->
        {:noreply,
         socket |> stream_insert(:courses, course) |> push_patch(to: ~p"/tutor/my-courses")}

      {:error, cs} ->
        {:noreply, assign(socket, form: to_form(cs))}
    end
  end

  defp consume_banner_image_upload(socket) do
    uploaded_images =
      consume_uploaded_entries(socket, :banner_image, fn %{path: path}, entry ->
        filename = "#{entry.uuid}.#{ext(entry)}"
        dist = Path.join([:code.priv_dir(:lukas), "static", "images", filename])

        File.cp!(path, dist)

        {:ok, dist}
      end)

    case uploaded_images do
      [entry] -> entry
      [] -> Course.default_banner_image()
    end
  end

  defp ext(upload_entry) do
    [ext | _] = MIME.extensions(upload_entry.client_type)
    ext
  end

  def handle_info({:staff_status, :added_to_course, course}, socket) do
    {:noreply, stream_insert(socket, :courses, course)}
  end

  def handle_info({:staff_status, :removed_from_course, course}, socket) do
    {:noreply, stream_delete(socket, :courses, course)}
  end
end
