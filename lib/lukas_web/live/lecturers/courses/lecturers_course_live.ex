defmodule LukasWeb.Lecturer.CourseLive do
  use LukasWeb, :live_view

  alias Lukas.Learning
  alias Lukas.Learning.Course
  alias Lukas.Learning.Course.Content

  def mount(%{"id" => raw_id}, _session, socket) do
    with {id, _} <- Integer.parse(raw_id),
         {course, lecturers} when course != nil <-
           Course.Staff.get_course_with_lecturers(id) do
      Learning.watch_course(course)

      {:ok,
       socket |> assign(course: course) |> load_lessons(course) |> stream(:lecturers, lecturers)}
    else
      _ -> {:ok, redirect(socket, to: ~p"/")}
    end
  end

  def handle_params(_, _, socket) when socket.assigns.live_action == :new_lesson do
    cs = Content.create_lesson_changeset(socket.assigns.course, %{})
    form = to_form(cs)
    {:noreply, assign(socket, form: form)}
  end

  def handle_params(%{"lesson_id" => raw_id}, _, socket)
      when socket.assigns.live_action == :edit_lesson do
    with {lesson_id, _} <- Integer.parse(raw_id),
         lesson when lesson != nil <-
           Content.get_lesson(socket.assigns.course.id, lesson_id) do
      cs = Content.edit_lesson_changeset(lesson)
      form = to_form(cs)
      {:noreply, assign(socket, form: form, lesson: lesson)}
    else
      _ -> {:noreply, redirect(socket, to: ~p"/tutor/my-courses/#{socket.assigns.course.id}")}
    end
  end

  def handle_params(_, _, socket), do: {:noreply, socket}

  def load_lessons(socket, course), do: stream(socket, :lessons, Learning.get_lessons(course))

  def render(assigns) do
    ~H"""
    <.modal
      :if={@live_action == :add_lecturer}
      id="new-lecturer-modal"
      on_cancel={JS.patch(~p"/tutor/my-courses/#{@course.id}")}
      show
    >
      <ul id="lecturers-list" phx-update="stream">
        <li :for={{id, lect} <- @streams.possible_lecturers} id={id}>
          <.button phx-click="add-lecturer" phx-value-lecturer-id={lect.id}><%= lect.name %></.button>
        </li>
      </ul>
    </.modal>

    <.modal
      :if={@live_action in [:new_lesson, :edit_lesson]}
      id="new-lesson-modal"
      on_cancel={JS.patch(~p"/tutor/my-courses/#{@course.id}")}
      show
    >
      <.form
        for={@form}
        phx-change="validate"
        phx-submit={if @live_action == :new_lesson, do: "create", else: "update"}
      >
        <.input type="text" label="Title" field={@form[:title]} />
        <.input type="textarea" label="Description" field={@form[:description]} />
        <.button>Create</.button>
      </.form>
    </.modal>

    <h1>Course <%= @course.name %></h1>

    <.link patch={~p"/tutor/my-courses/#{@course.id}/new-lesson"}>
      <.button>New lesson</.button>
    </.link>

    <ul id="lessons" phx-update="stream">
      <li :for={{id, lesson} <- @streams.lessons} id={id}>
        <%= lesson.title %> |
        <.link patch={~p"/tutor/my-courses/#{@course.id}/lessons/#{lesson.id}/edit-lesson"}>
          Edit
        </.link>
        |
        <.button id={"lesson-delete-#{lesson.id}"} phx-click="delete-lesson" phx-value-id={lesson.id}>
          Delete lesson
        </.button>
      </li>
    </ul>

    <h3>Lecturers</h3>

    <ul id="lecturers" phx-update="stream">
      <li :for={{id, lect} <- @streams.lecturers} id={id}>
        <%= lect.name %> |
        <.button
          id={"lecturer-delete-#{lect.id}"}
          phx-click="delete-lecturer"
          phx-value-lecturer-id={lect.id}
        >
          Remove
        </.button>
      </li>
    </ul>
    """
  end

  def handle_event("validate", %{"lesson" => params}, socket) do
    form = to_form(Content.validate_lesson(socket.assigns.course, params))
    {:noreply, assign(socket, form: form)}
  end

  def handle_event("create", %{"lesson" => params}, socket) do
    case Content.create_lesson(socket.assigns.course, params) do
      {:ok, _} ->
        {:noreply, push_patch(socket, to: ~p"/tutor/my-courses/#{socket.assigns.course.id}")}

      {:error, cs} ->
        {:noreply, assign(socket, form: to_form(cs))}
    end
  end

  def handle_event("update", %{"lesson" => params}, socket) do
    case Content.update_lesson(socket.assigns.lesson, params) do
      {:ok, _} ->
        {:noreply, push_patch(socket, to: ~p"/tutor/my-courses/#{socket.assigns.course.id}")}

      {:error, cs} ->
        {:noreply, assign(socket, form: to_form(cs))}
    end
  end

  def handle_event("delete-lesson", %{"id" => raw_id}, socket) do
    {lesson_id, _} = Integer.parse(raw_id)
    {:ok, _} = Content.remove_lesson(lesson_id)
    {:noreply, socket}
  end

  def handle_info({:course, _, :lesson_added, lesson}, socket) do
    {:noreply, stream_insert(socket, :lessons, lesson)}
  end

  def handle_info({:course, _, :lesson_updated, lesson}, socket) do
    {:noreply, stream_insert(socket, :lessons, lesson)}
  end

  def handle_info({:course, _, :lesson_deleted, lesson}, socket) do
    {:noreply, stream_delete(socket, :lessons, lesson)}
  end

  def handle_info({:course, _, :lecturer_added, lecturer}, socket) do
    {:noreply, stream_insert(socket, :lecturers, lecturer)}
  end

  def handle_info({:course, _, :lecturer_removed, lecturer}, socket) do
    {:noreply, stream_delete(socket, :lecturers, lecturer)}
  end

  def handle_info({:course, _, :student_enrolled, student}, socket) do
    {:noreply, socket |> put_flash(:info, "#{student.id} enrolled in the course")}
  end
end
