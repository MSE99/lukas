defmodule LukasWeb.Operator.CourseLive do
  use LukasWeb, :live_view

  alias Lukas.Learning

  def mount(%{"id" => raw_id}, _session, socket) do
    with {id, _} <- Integer.parse(raw_id), course when course != nil <- Learning.get_course(id) do
      Learning.watch_course(course)
      {:ok, socket |> assign(course: course) |> load_lessons(course)}
    else
      _ -> {:ok, redirect(socket, to: ~p"/")}
    end
  end

  def handle_params(_, _, socket) when socket.assigns.live_action == :new_lesson do
    cs = Learning.create_lesson_changeset(socket.assigns.course, %{})
    form = to_form(cs)

    {:noreply, assign(socket, form: form)}
  end

  def handle_params(_, _, socket), do: {:noreply, socket}

  def load_lessons(socket, course), do: stream(socket, :lessons, Learning.get_lessons(course))

  def render(assigns) do
    ~H"""
    <.modal
      :if={@live_action == :new_lesson}
      id="new-lesson-modal"
      on_cancel={JS.patch(~p"/controls/courses/#{@course.id}")}
      show
    >
      <.form for={@form} phx-change="validate" phx-submit="create">
        <.input type="text" label="Title" field={@form[:title]} />
        <.input type="textarea" label="Description" field={@form[:description]} />
        <.button>Create</.button>
      </.form>
    </.modal>

    <h1>Course <%= @course.name %></h1>

    <.link patch={~p"/controls/courses/#{@course.id}/new-lesson"}>
      <.button>New lesson</.button>
    </.link>

    <ul id="lessons" phx-update="stream">
      <li :for={{id, lesson} <- @streams.lessons} id={id}>
        <%= lesson.title %>
      </li>
    </ul>
    """
  end

  def handle_event("validate", %{"lesson" => params}, socket) do
    form = to_form(Learning.validate_lesson(socket.assigns.course, params))
    {:noreply, assign(socket, form: form)}
  end

  def handle_event("create", %{"lesson" => params}, socket) do
    case Learning.create_lesson(socket.assigns.course, params) do
      {:ok, _} ->
        {:noreply, push_patch(socket, to: ~p"/controls/courses/#{socket.assigns.course.id}")}

      {:error, cs} ->
        {:noreply, assign(socket, form: to_form(cs))}
    end
  end

  def handle_info({:course, _, :lesson_added, lesson}, socket) do
    {:noreply, stream_insert(socket, :lessons, lesson)}
  end
end
