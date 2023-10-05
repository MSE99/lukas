defmodule LukasWeb.Lecturer.CoursesLive do
  use LukasWeb, :live_view

  alias Lukas.{Learning, Categories}

  def mount(_, _, socket) do
    lecturer = socket.assigns.current_user

    Learning.Course.Staff.watch_staff_status(lecturer.id)

    courses = Learning.Course.Staff.list_lecturer_courses(lecturer.id)
    {:ok, socket |> stream(:courses, courses)}
  end

  def handle_params(_, _, socket) when socket.assigns.live_action == :new do
    cs = Learning.create_course_changeset()
    form = to_form(cs)
    tags = Categories.list_tags()
    {:noreply, assign(socket, form: form, tags: tags, chosen_tag_ids: [])}
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
      :if={@live_action == :new}
      id="new-course-modal"
      on_cancel={JS.patch(~p"/tutor/my-courses")}
      show
    >
      <.form for={@form} phx-change="validate" phx-submit="create">
      <.input field={@form[:name]} type="text" label="Name" phx-debounce="blur" />
      <.input field={@form[:price]} type="number" label="Name" phx-debounce="blur" />

        <div>
          <span
            :for={tag <- @tags}
            id={"tags-#{tag.id}"}
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

        <.button>Create</.button>
      </.form>
    </.modal>
    """
  end

  def handle_event("toggle-tag", %{"id" => raw_tag_id}, socket) do
    tag_id = String.to_integer(raw_tag_id)
    chosen_tags = socket.assigns.chosen_tag_ids

    case Enum.find(chosen_tags, nil, fn other_id -> other_id == tag_id end) do
      nil ->
        {:noreply, assign(socket, chosen_tag_ids: [tag_id | chosen_tags])}

      _ ->
        {:noreply,
         assign(socket,
           chosen_tag_ids: Enum.filter(chosen_tags, fn other_id -> other_id != tag_id end)
         )}
    end
  end

  def handle_event("validate", %{"course" => params}, socket) do
    cs = Learning.validate_course(params)
    form = to_form(cs)
    {:noreply, socket |> assign(form: form)}
  end

  def handle_event("create", %{"course" => params}, socket) do
    result =
      Learning.create_course_by_lecturer(
        params,
        socket.assigns.chosen_tag_ids,
        socket.assigns.current_user,
        fn course ->
          Learning.Course.Staff.emit_course_created_by_lecturer(
            course,
            socket.assigns.current_user
          )

          nil
        end
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

  def handle_info({:staff_status, :added_to_course, course}, socket) do
    {:noreply, stream_insert(socket, :courses, course)}
  end

  def handle_info({:staff_status, :removed_from_course, course}, socket) do
    {:noreply, stream_delete(socket, :courses, course)}
  end
end
