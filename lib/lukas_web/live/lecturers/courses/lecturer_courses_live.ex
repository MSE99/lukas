defmodule LukasWeb.Lecturer.CoursesLive do
  use LukasWeb, :live_view

  alias Lukas.{Learning, Categories}
  alias Lukas.Learning.Course

  alias Phoenix.LiveView.AsyncResult
  alias LukasWeb.CommonComponents

  def mount(_, _, socket) do
    lecturer = socket.assigns.current_user

    next_socket =
      socket
      |> stream_configure(:courses, [])
      |> assign(:loading, AsyncResult.loading())
      |> start_async(:loading, fn -> Learning.Course.Staff.list_lecturer_courses(lecturer.id) end)
      |> allow_upload(:banner_image, accept: ~w(.jpg .jpeg .png .webp))

    {:ok, next_socket}
  end

  def handle_async(:loading, {:ok, courses}, socket) do
    Learning.Course.Staff.watch_staff_status(socket.assigns.current_user.id)

    {:noreply,
     socket
     |> stream(:courses, courses)
     |> assign(:loading, AsyncResult.ok(socket.assigns.loading, nil))}
  end

  def handle_async(:loading, {:exit, reason}, socket) do
    {:noreply, assign(socket, loading: AsyncResult.failed(socket.assigns.loading, reason))}
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
    <CommonComponents.navigate_breadcrumbs links={[
      {~p"/tutor", "home"},
      {~p"/tutor/my-courses", "my courses"}
    ]} />

    <.link patch={~p"/tutor/my-courses/new"}>
      <.button class="flex items-center px-4 ml-auto">
        <.icon name="hero-plus-circle-solid" class="mr-3" /> New Course
      </.button>
    </.link>

    <.async_result assign={@loading}>
      <:loading>Loading...</:loading>
      <:failed>failed...</:failed>

      <ul id="courses" phx-update="stream" class="mt-5">
        <li
          :for={{id, course} <- @streams.courses}
          id={id}
          class="mb-2 flex items-center text-secondary font-bold mb-3"
        >
          <img src={~p"/images/#{course.banner_image}"} width={80} height={80} class="rounded" />

          <.link navigate={~p"/tutor/my-courses/#{course.id}"} class="ml-5 hover:underline">
            <%= course.name %>
          </.link>

          <.link class="ml-auto" patch={~p"/tutor/my-courses/#{course.id}/edit"}>
            <.icon name="hero-pencil-solid" />
          </.link>
        </li>
      </ul>
    </.async_result>

    <.modal
      :if={@live_action in [:new, :edit]}
      id="new-course-modal"
      on_cancel={JS.patch(~p"/tutor/my-courses")}
      show
    >
      <h1 class="mb-5 font-bold text-lg text-primary">Create new course</h1>

      <.form
        for={@form}
        phx-change="validate"
        phx-submit={if @live_action == :edit, do: "edit", else: "create"}
      >
        <.input field={@form[:name]} type="text" label="Name" phx-debounce="blur" />
        <.input field={@form[:price]} type="number" label="Price" phx-debounce="blur" />
        <.input field={@form[:description]} type="textarea" label="Description" phx-debounce="blur" />

        <p class="font-semibold mt-5">Tags</p>
        <ul id="tags" phx-update="stream" class="mt-3 flex flex-wrap gap-2">
          <li
            :for={{id, tag} <- @streams.tags}
            id={id}
            phx-click="toggle-tag"
            phx-value-id={tag.id}
            class={[
              "hover:bg-green-600 hover:text-white transition-all hover:cursor-pointer font-bold text-sm px-4 py-1 rounded-full",
              if(
                tag.id in @chosen_tag_ids,
                do: "bg-primary text-white",
                else: "bg-gray-300 text-secondary"
              )
            ]}
          >
            <%= tag.name %>
          </li>
        </ul>

        <div class="my-5">
          <p class="font-bold mb-3">Banner image</p>
          <.live_file_input upload={@uploads.banner_image} />
        </div>

        <%= for entry <- @uploads.banner_image.entries do %>
          <progress value={entry.progress} max="100"></progress>

          <%= for err <- upload_errors(@uploads.banner_image, entry) do %>
            <p class="alert alert-danger"><%= error_to_string(err) %></p>
          <% end %>
        <% end %>

        <div class="flex justify-end">
          <.button class="px-10">Create</.button>
        </div>
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

        {:ok, filename}
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
