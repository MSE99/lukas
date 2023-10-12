defmodule LukasWeb.Operator.AllCoursesLive do
  use LukasWeb, :live_view

  alias Lukas.Learning
  alias Lukas.Learning.Course
  alias Lukas.Categories
  alias Phoenix.LiveView.AsyncResult

  def mount(params, _, socket) do
    next_socket =
      socket
      |> stream_configure(:courses, [])
      |> stream_configure(:tags, [])
      |> assign(:loading, AsyncResult.loading())
      |> start_async(:loading, &load_courses_and_tags/0)
      |> apply_action(params, socket.assigns.live_action)
      |> allow_upload(:banner_image, accept: ~w(.jpg .jpeg .png .webp))

    {:ok, next_socket}
  end

  defp load_courses_and_tags() do
    {Learning.list_courses(), Categories.list_tags()}
  end

  def handle_async(:loading, {:ok, {courses, tags}}, socket) do
    Learning.watch_courses()

    next_socket =
      socket
      |> assign(loading: AsyncResult.ok(socket.assigns.loading, nil))
      |> assign(:per_page, 50)
      |> assign(:page, 1)
      |> assign(:end_of_timeline?, false)
      |> stream(:courses, courses)
      |> stream(:tags, tags)

    {:noreply, next_socket}
  end

  def handle_async(:loading, {:exit, reason}, socket) do
    {:noreply,
     socket
     |> assign(loading: AsyncResult.failed(socket.assigns.loading, reason))}
  end

  def handle_params(_, _, socket), do: {:noreply, socket}

  defp paginate_courses(socket, page) when page >= 1 do
    %{page: current_page, per_page: per_page} = socket

    courses = Learning.list_courses(limit: per_page, offset: (page - 1) * per_page)

    {items, limit, at} =
      if page >= current_page do
        {courses, per_page * 3 * -1, -1}
      else
        {Enum.reverse(courses), per_page * 3, 0}
      end

    case items do
      [] ->
        socket
        |> assign(:end_of_timeline?, at == -1)

      [_ | _] ->
        socket
        |> assign(:end_of_timeline?, false)
        |> assign(:page, page)
        |> stream(:courses, items, limit: limit, at: at)
    end
  end

  def apply_action(socket, _, :new) do
    cs = Learning.create_course_changeset()
    form = to_form(cs)

    socket
    |> assign(form: form)
    |> assign(tag_ids: [])
  end

  def apply_action(socket, _, _) do
    socket
    |> assign(form: nil)
    |> assign(tag_ids: nil)
  end

  def render(assigns) do
    ~H"""
    <h1>All courses</h1>

    <.async_result assign={@loading}>
      <:loading>Loading courses</:loading>
      <:failed>Failed to load courses</:failed>

      <ul
        phx-update="stream"
        id="async-courses"
        phx-viewport-top={@page > 1 && "reached-top"}
        phx-viewport-bottom={@end_of_timeline? == false && "reached-bottom"}
        class={[
          @end_of_timeline? == false && "pb-[200vh]",
          @page > 1 && "pt-[200vh]"
        ]}
      >
        <li :for={{id, course} <- @streams.courses} id={id}>
          <.link navigate={~p"/controls/courses/#{course.id}"}><%= course.name %></.link>
        </li>
      </ul>
    </.async_result>

    <.modal
      :if={@live_action == :new}
      id="new-course-modal"
      on_cancel={JS.patch(~p"/controls/courses")}
      show
    >
      <.form for={@form} phx-change="validate" phx-submit="create">
        <.input field={@form[:name]} type="text" label="Name" phx-debounce="blur" />
        <.input field={@form[:price]} type="number" label="Price" phx-debounce="blur" />

        <.async_result assign={@loading}>
          <:loading>Loading courses</:loading>
          <:failed>Failed to load courses</:failed>

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
        </.async_result>

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

  def handle_event("reached-top", _, socket) do
    next_page =
      if socket.assigns.page == 1 do
        1
      else
        socket.assigns.page - 1
      end

    {:noreply, paginate_courses(socket, next_page)}
  end

  def handle_event("reached-bottom", _, socket) do
    {:noreply, paginate_courses(socket, socket.assigns.page + 1)}
  end

  def handle_event("validate", %{"course" => course_attrs}, socket) do
    cs = Learning.validate_course(course_attrs)
    form = to_form(cs)
    {:noreply, assign(socket, form: form)}
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
    {:noreply, stream_insert(socket, :courses, course)}
  end

  def handle_info({:courses, :course_updated, course}, socket) do
    {:noreply, stream_insert(socket, :courses, course)}
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
