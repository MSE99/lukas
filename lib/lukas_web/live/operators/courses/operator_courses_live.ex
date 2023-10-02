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
      |> assign(:tags, Categories.list_tags())
      |> assign(:loading, AsyncResult.loading())
      |> start_async(:loading, &Learning.list_courses/0)
      |> apply_action(params, socket.assigns.live_action)

    {:ok, next_socket}
  end

  def handle_async(:loading, {:ok, courses}, socket) do
    {:noreply,
     socket
     |> assign(loading: AsyncResult.ok(socket.assigns.loading, false))
     |> stream(:courses, courses)}
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

  def apply_action(socket, _, _), do: socket

  def render(assigns) do
    ~H"""
    <.modal
      :if={@live_action == :new}
      id="new-course-modal"
      on_cancel={JS.patch(~p"/controls/courses")}
      show
    >
      <.form for={@form} phx-change="validate" phx-submit="create">
        <.input field={@form[:name]} type="text" label="Name" phx-debounce="blur" />

        <div>
          <span
            :for={tag <- @tags}
            id={"tags-#{tag.id}"}
            phx-click="toggle-tag"
            phx-value-id={tag.id}
            class={[
              tag.id in @tag_ids && "font-bold blue"
            ]}
          >
            <%= tag.name %>
          </span>
        </div>

        <.button>Create</.button>
      </.form>
    </.modal>

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
    {id, _} = Integer.parse(raw_id)
    %{tag_ids: tag_ids} = socket.assigns

    if Enum.find(tag_ids, nil, fn other_id -> other_id == id end) do
      {:noreply, assign(socket, tag_ids: Enum.filter(tag_ids, fn other_id -> other_id != id end))}
    else
      {:noreply, assign(socket, tag_ids: [id | tag_ids])}
    end
  end

  def handle_info({:courses, :course_created, course}, socket) do
    {:noreply, stream_insert(socket, :courses, course)}
  end

  def handle_info({:courses, :course_updated, course}, socket) do
    {:noreply, stream_insert(socket, :courses, course)}
  end
end
