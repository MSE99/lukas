defmodule LukasWeb.Operator.AllCoursesLive do
  use LukasWeb, :live_view

  alias Lukas.Learning
  alias Lukas.Learning.Course
  alias Lukas.Categories

  alias LukasWeb.PagedList
  alias LukasWeb.CommonComponents

  def mount(_, _, socket) do
    if connected?(socket) do
      Learning.watch_courses()
    end

    {:ok, allow_upload(socket, :banner_image, accept: ~w(.jpg .jpeg .png .webp))}
  end

  def handle_params(params, _, socket),
    do: {:noreply, apply_action(socket, params, socket.assigns.live_action)}

  defp apply_action(socket, _, :new) do
    tags = Categories.list_tags()
    cs = Learning.create_course_changeset()
    form = to_form(cs)

    socket
    |> assign(form: form)
    |> assign(tag_ids: [])
    |> stream(:tags, tags, reset: true)
  end

  defp apply_action(socket, %{"id" => raw_id}, :edit) do
    {course, course_tags} = raw_id |> String.to_integer() |> Learning.get_course_and_tags()
    tags = Categories.list_tags()
    form = to_form(Learning.update_course_changeset(course, %{}))

    socket
    |> assign(course: course)
    |> assign(form: form)
    |> assign(tag_ids: Enum.map(course_tags, & &1.id))
    |> stream(:tags, tags, reset: true)
  end

  defp apply_action(socket, _, _) do
    socket
    |> assign(course: nil)
    |> assign(form: nil)
    |> assign(tag_ids: nil)
  end

  def render(assigns) do
    ~H"""
    <CommonComponents.navigate_breadcrumbs links={[
      {~p"/controls", "home"},
      {~p"/controls/courses", "courses"}
    ]} />

    <.link patch={~p"/controls/courses/new"} class="flex justify-end mt-10 mb-16">
      <.button class="px-5">Create course</.button>
    </.link>

    <.live_component
      module={PagedList}
      id="courses-list"
      page={1}
      limit={50}
      load={fn opts -> Learning.list_courses(opts) end}
      entry_dom_id={fn course -> "courses-#{course.id}" end}
    >
      <:item :let={course} class="flex items-center text-secondary font-bold">
        <img src={~p"/images/#{course.banner_image}"} width={80} height={80} class="rounded" />

        <.link navigate={~p"/controls/courses/#{course.id}"} class="ml-5 hover:underline">
          <%= course.name %>
        </.link>

        <.link class="ml-auto" patch={~p"/controls/courses/#{course.id}/edit"}>
          <.icon name="hero-pencil-solid" />
        </.link>
      </:item>
    </.live_component>

    <.modal
      :if={@live_action in [:new, :edit]}
      id="new-course-modal"
      on_cancel={JS.patch(~p"/controls/courses")}
      show
    >
      <.form
        for={@form}
        phx-change="validate"
        phx-submit={if @live_action == :edit, do: "edit", else: "create"}
      >
        <.input field={@form[:name]} type="text" label="Name" phx-debounce="blur" />
        <.input field={@form[:price]} type="number" label="Price" phx-debounce="blur" />
        <.input field={@form[:description]} type="textarea" label="Description" phx-debounce="blur" />

        <div id="tags" phx-update="stream">
          <span
            :for={{id, tag} <- @streams.tags}
            id={id}
            phx-click="toggle-tag"
            phx-value-id={tag.id}
            class={[
              tag.id in @tag_ids && "font-bold"
            ]}
          >
            <%= tag.name %>
          </span>
        </div>

        <.live_file_input upload={@uploads.banner_image} />

        <%= for entry <- @uploads.banner_image.entries do %>
          <progress value={entry.progress} max="100">
            <%= entry.progress %>%
          </progress>

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

  def handle_event("validate", %{"course" => course_attrs}, socket) do
    cs = Learning.validate_course(course_attrs)
    form = to_form(cs)
    {:noreply, assign(socket, form: form)}
  end

  def handle_event("edit", %{"course" => attrs}, socket) do
    opts = [
      get_banner_image_path: fn -> consume_banner_image_upload(socket) end,
      tag_ids: socket.assigns.tag_ids
    ]

    case Learning.update_course(socket.assigns.course, attrs, opts) do
      {:ok, _} ->
        {:noreply, push_patch(socket, to: ~p"/controls/courses")}

      {:error, cs} ->
        {:noreply, assign(socket, form: to_form(cs))}
    end
  end

  def handle_event("create", %{"course" => attrs}, socket) do
    opts = [
      get_banner_image_path: fn -> consume_banner_image_upload(socket) end,
      tag_ids: socket.assigns.tag_ids
    ]

    case Learning.create_course(attrs, opts) do
      {:ok, _} ->
        {:noreply, push_patch(socket, to: ~p"/controls/courses")}

      {:error, cs} ->
        {:noreply, assign(socket, form: to_form(cs))}
    end
  end

  def handle_event("toggle-tag", %{"id" => raw_id}, socket) do
    id = String.to_integer(raw_id)
    tag = Categories.get_tag!(id)
    tag_ids = socket.assigns.tag_ids

    if Enum.find(tag_ids, nil, fn other_id -> other_id == id end) do
      next_socket =
        socket
        |> assign(tag_ids: Enum.filter(tag_ids, fn other_id -> other_id != id end))
        |> stream_insert(:tags, tag)

      {:noreply, next_socket}
    else
      {:noreply, socket |> assign(tag_ids: [id | tag_ids]) |> stream_insert(:tags, tag)}
    end
  end

  def handle_info({:courses, :course_created, course}, socket) do
    send_update(self(), LukasWeb.PagedList, id: "courses-list", first_page_insert: course)
    {:noreply, socket}
  end

  def handle_info({:courses, :course_updated, course}, socket) do
    send_update(self(), LukasWeb.PagedList, id: "courses-list", replace: course)
    {:noreply, socket}
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
end
