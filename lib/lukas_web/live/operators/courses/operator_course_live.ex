defmodule LukasWeb.Operator.CourseLive do
  use LukasWeb, :live_view

  alias Lukas.Learning
  alias Lukas.Learning.Course
  alias Lukas.Learning.Course.Content

  alias LukasWeb.CommonComponents

  def mount(%{"id" => raw_id}, _session, socket) do
    with {id, _} <- Integer.parse(raw_id),
         {course, lecturers, tags} when course != nil <-
           Course.Staff.get_course_with_lecturers(id) do
      Learning.watch_course(course)

      {:ok,
       socket
       |> assign(course: course)
       |> load_lessons(course)
       |> stream(:lecturers, lecturers)
       |> stream(:tags, tags)}
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
      _ -> {:noreply, redirect(socket, to: ~p"/controls/courses/#{socket.assigns.course.id}")}
    end
  end

  def handle_params(_, _, socket) when socket.assigns.live_action == :add_lecturer do
    possible_lecturers = Course.Staff.possible_lecturers_for(socket.assigns.course)
    {:noreply, stream(socket, :possible_lecturers, possible_lecturers, reset: true)}
  end

  def handle_params(_, _, socket), do: {:noreply, socket}

  def load_lessons(socket, course), do: stream(socket, :lessons, Learning.get_lessons(course))

  def render(assigns) do
    ~H"""
    <CommonComponents.navigate_breadcrumbs links={[
      {~p"/controls", "home"},
      {~p"/controls/courses", "courses"},
      {~p"/controls/courses/#{@course.id}", @course.name}
    ]} />

    <CommonComponents.course_banner image_src={~p"/images/#{@course.banner_image}"} />

    <.link patch={~p"/controls/courses/#{@course.id}/new-lesson"}>
      <CommonComponents.transparent_button>
        Lessons <.icon name="hero-plus-circle-solid" class="ml-2" />
      </CommonComponents.transparent_button>
    </.link>

    <ul id="lessons" phx-update="stream" class="my-10">
      <li
        :for={{id, lesson} <- @streams.lessons}
        id={id}
        class="flex gap-2 text-black font-bold text-lg"
      >
        <.link
          navigate={~p"/controls/courses/#{@course.id}/lessons/#{lesson.id}"}
          class="hover:underline mr-auto"
        >
          <%= lesson.title %>
        </.link>

        <.link patch={~p"/controls/courses/#{@course.id}/lessons/#{lesson.id}/edit-lesson"}>
          <.icon name="hero-pencil-solid text-secondary hover:text-blue-300" />
        </.link>

        <span id={"lesson-delete-#{lesson.id}"} phx-click="delete-lesson" phx-value-id={lesson.id}>
          <.icon name="hero-trash-solid text-secondary hover:text-red-500 hover:cursor-pointer" />
        </span>
      </li>
    </ul>

    <CommonComponents.streamed_users_mini_list
      id="lecturers-list"
      title="Lecturers"
      users={@streams.lecturers}
    />

    <div class="mt-5 flex justify-end pb-5">
      <.link navigate={~p"/controls/courses/#{@course.id}/assign-lecturer"}>
        <CommonComponents.transparent_button>
          <.icon name="hero-pencil" class="mr-3" /> Manage lecturers
        </CommonComponents.transparent_button>
      </.link>
    </div>

    <div>
      <CommonComponents.streamed_tag_list id="tags-list" title="Tags" tags={@streams.tags} />
    </div>

    <h3 class="mt-5 pb-5 font-bold text-primary">
      Price <%= :erlang.float_to_binary(@course.price, decimals: 1) %> LYD
    </h3>

    <.modal
      :if={@live_action in [:new_lesson, :edit_lesson]}
      id="new-lesson-modal"
      on_cancel={JS.patch(~p"/controls/courses/#{@course.id}")}
      show
    >
      <h1 class="mb-5 font-bold text-lg text-primary">
        <%= if @live_action == :new_lesson, do: "Create new lesson", else: "Update #{@lesson.title}" %>
      </h1>

      <.form
        for={@form}
        phx-change="validate"
        phx-submit={if @live_action == :new_lesson, do: "create", else: "update"}
      >
        <.input type="text" label="Title" field={@form[:title]} />
        <.input type="textarea" label="Description" field={@form[:description]} />

        <div class="mt-5 flex justify-end">
          <.button class="px-8">Create</.button>
        </div>
      </.form>
    </.modal>
    """
  end

  def handle_event("validate", %{"lesson" => params}, socket) do
    form = to_form(Content.validate_lesson(socket.assigns.course, params))
    {:noreply, assign(socket, form: form)}
  end

  def handle_event("create", %{"lesson" => params}, socket) do
    case Content.create_lesson(socket.assigns.course, params) do
      {:ok, _} ->
        {:noreply, push_patch(socket, to: ~p"/controls/courses/#{socket.assigns.course.id}")}

      {:error, cs} ->
        {:noreply, assign(socket, form: to_form(cs))}
    end
  end

  def handle_event("update", %{"lesson" => params}, socket) do
    case Content.update_lesson(socket.assigns.lesson, params) do
      {:ok, _} ->
        {:noreply, push_patch(socket, to: ~p"/controls/courses/#{socket.assigns.course.id}")}

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
