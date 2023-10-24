defmodule LukasWeb.Operator.CourseLessonsLive do
  use LukasWeb, :live_view

  alias Lukas.Learning

  alias LukasWeb.CommonComponents
  alias Phoenix.LiveView.AsyncResult

  def mount(params, _session, socket) do
    {:ok,
     socket
     |> stream_configure(:lessons, [])
     |> assign(:loading, AsyncResult.loading())
     |> start_async(:loading, fn -> load_course_with_lessons(params) end)
     |> assign(:show_form_modal, false)}
  end

  defp load_course_with_lessons(%{"id" => raw_id}) do
    with {id, _} <- Integer.parse(raw_id), course when course != nil <- Learning.get_course(id) do
      lessons = Learning.get_lessons(course)
      {course, lessons}
    else
      _ -> :error
    end
  end

  def handle_async(:loading, {:ok, {course, lessons}}, socket) do
    Learning.watch_course(course)

    form = Learning.Course.Content.create_lesson_changeset(course) |> to_form()

    next_socket =
      socket
      |> assign(:loading, AsyncResult.ok(socket.assigns.loading, nil))
      |> assign(:course, course)
      |> assign(:form, form)
      |> assign(:lesson, nil)
      |> stream(:lessons, lessons)

    {:noreply, next_socket}
  end

  def handle_async(:loading, {:ok, :error}, socket) do
    {:noreply, redirect(socket, to: ~p"/controls/courses")}
  end

  def handle_async(:loading, {:exit, reason}, socket) do
    next_socket =
      socket
      |> assign(:loading, AsyncResult.failed(socket.assigns.loading, reason))

    {:noreply, next_socket}
  end

  def render(assigns) do
    ~H"""
    <.async_result assign={@loading}>
      <:loading><.loading_spinner /></:loading>
      <:failed>Failed...</:failed>

      <CommonComponents.navigate_breadcrumbs links={[
        {~p"/controls", "home"},
        {~p"/controls/courses/#{@course.id}", @course.name},
        {~p"/controls/courses/#{@course.id}/lessons", "lessons"}
      ]} />

      <div class="flex justify-end">
        <.button id="new-button" phx-click="prep-create" class="px-5 flex items-center">
          Add lesson <.icon name="hero-plus-circle-solid ml-2" />
        </.button>
      </div>

      <ul id="lessons" phx-update="stream" class="mt-10">
        <li :for={{id, lesson} <- @streams.lessons} id={id} class="flex items-center gap-2">
          <.link navigate={~p"/controls/courses/#{@course.id}/lessons/#{lesson.id}"}>
            <strong class="text-lg underline lg:no-underline hover:underline">
              <%= lesson.title %>
            </strong>
          </.link>

          <span
            id={"lessons-#{lesson.id}-edit"}
            phx-click={
              JS.push("prep-edit", value: %{id: lesson.id}, page_loading: true)
              |> show_modal("form-modal")
            }
            class="ml-auto hover:cursor-pointer"
          >
            <.icon name="hero-pencil-solid text-secondary hover:text-blue-300" />
          </span>

          <span id={"lessons-#{lesson.id}-delete"} phx-click="delete" phx-value-id={lesson.id}>
            <.icon name="hero-trash-solid text-secondary hover:text-red-500 hover:cursor-pointer" />
          </span>
        </li>
      </ul>

      <.modal :if={@show_form_modal} id="form-modal" on_cancel={JS.push("clear")} show>
        <.form for={@form} phx-change="validate" phx-submit={if @lesson, do: "edit", else: "create"}>
          <.input type="text" label="Title" field={@form[:title]} />
          <.input type="textarea" label="Description" field={@form[:description]} />

          <div class="mt-5 flex justify-end">
            <.button class="px-8">Create</.button>
          </div>
        </.form>
      </.modal>
    </.async_result>
    """
  end

  def handle_event("clear", _, socket) do
    form = Learning.Course.Content.create_lesson_changeset(socket.assigns.course) |> to_form()

    {:noreply,
     socket |> assign(:lesson, nil) |> assign(:form, form) |> assign(:show_form_modal, false)}
  end

  def handle_event("prep-create", _, socket) do
    {:noreply, assign(socket, :show_form_modal, true)}
  end

  def handle_event("prep-edit", %{"id" => id}, socket) do
    lesson = Learning.Course.Content.get_lesson!(socket.assigns.course.id, id)
    cs = Learning.Course.Content.edit_lesson_changeset(lesson, %{})
    form = to_form(cs)

    {:noreply,
     socket |> assign(:lesson, lesson) |> assign(form: form) |> assign(:show_form_modal, true)}
  end

  def handle_event("edit", %{"lesson" => params}, socket) do
    case Learning.Course.Content.update_lesson(socket.assigns.lesson, params) do
      {:ok, lesson} ->
        next_form =
          Learning.Course.Content.create_lesson_changeset(socket.assigns.course) |> to_form()

        {:noreply,
         socket
         |> stream_insert(:lessons, lesson)
         |> assign(:lesson, nil)
         |> assign(:form, next_form)
         |> assign(:show_form_modal, false)}

      {:error, cs} ->
        {:noreply, assign(socket, form: to_form(cs))}
    end
  end

  def handle_event("create", %{"lesson" => params}, socket) do
    case Learning.Course.Content.create_lesson(socket.assigns.course, params) do
      {:ok, lesson} ->
        next_form =
          Learning.Course.Content.create_lesson_changeset(socket.assigns.course) |> to_form()

        {:noreply,
         stream_insert(socket, :lessons, lesson)
         |> assign(:show_form_modal, false)
         |> assign(:form, next_form)}

      {:error, cs} ->
        {:noreply, assign(socket, form: to_form(cs))}
    end
  end

  def handle_event("validate", %{"lesson" => params}, socket) do
    cs = Learning.Course.Content.validate_lesson(socket.assigns.course, params)
    form = to_form(cs)
    {:noreply, assign(socket, form: form)}
  end

  # TODO: Replace this insecure code, attacker can use
  # the id parameter to delete any lesson on the system. 
  def handle_event("delete", %{"id" => raw_id}, socket) do
    raw_id
    |> String.to_integer()
    |> Learning.Course.Content.remove_lesson()

    {:noreply, socket |> stream_delete_by_dom_id(:lessons, "lessons-#{raw_id}")}
  end

  def handle_info({:course, _, :lesson_added, lesson}, socket) do
    {:noreply, stream_insert(socket, :lessons, lesson)}
  end

  def handle_info({:course, _, :lesson_deleted, lesson}, socket) do
    {:noreply, stream_delete(socket, :lessons, lesson)}
  end

  def handle_info({:course, _, :lesson_updated, lesson}, socket) do
    {:noreply, stream_insert(socket, :lessons, lesson)}
  end

  def handle_info({:course, _, :course_updated, course}, socket) do
    {:noreply, assign(socket, :course, course)}
  end

  def handle_info({:course, _, _, _}, socket), do: {:noreply, socket}
end
