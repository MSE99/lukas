defmodule LukasWeb.Operator.AllCoursesLive do
  use LukasWeb, :live_view

  alias Lukas.Learning
  alias Lukas.Categories
  alias Phoenix.LiveView.AsyncResult

  def mount(params, _, socket) do
    if connected?(socket) do
      Learning.watch_courses()
    end

    next_socket =
      socket
      |> stream_configure(:courses, [])
      |> stream_configure(:tags, [])
      |> assign(:loading, AsyncResult.loading())
      |> start_async(:loading, &load_courses_and_tags/0)
      |> apply_action(params, socket.assigns.live_action)

    {:ok, next_socket}
  end

  defp load_courses_and_tags() do
    {Learning.list_courses(), Categories.list_tags()}
  end

  def handle_async(:loading, {:ok, {courses, tags}}, socket) do
    next_socket =
      socket
      |> assign(loading: AsyncResult.ok(socket.assigns.loading, nil))
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

      <ul phx-update="stream" id="async-courses">
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

        <.button>Create</.button>
      </.form>
    </.modal>
    """
  end

  def handle_event("validate", %{"course" => course_attrs}, socket) do
    cs = Learning.validate_course(course_attrs)
    form = to_form(cs)
    {:noreply, assign(socket, form: form)}
  end

  def handle_event("create", %{"course" => attrs}, socket) do
    case Learning.create_course(attrs, socket.assigns.tag_ids) do
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
end
