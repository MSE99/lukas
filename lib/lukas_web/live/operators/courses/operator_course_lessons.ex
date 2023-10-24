defmodule LukasWeb.Operator.CourseLessonsLive do
  use LukasWeb, :live_view

  alias Lukas.Learning

  alias Phoenix.LiveView.AsyncResult
  alias Lukas.Learning

  def mount(params, _session, socket) do
    {:ok,
     socket
     |> stream_configure(:lessons, [])
     |> assign(:loading, AsyncResult.loading())
     |> start_async(:loading, fn -> load_course_with_lessons(params) end)}
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

      <h1><%= @course.name %></h1>

      <ul id="lessons" phx-update="stream">
        <li :for={{id, lesson} <- @streams.lessons} id={id}>
          <%= lesson.title %>
        </li>
      </ul>

      <.modal id="form-modal">
        <.form for={@form} phx-change="validate" phx-submit="create">
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

  def handle_event("create", %{"lesson" => params}, socket) do
    case Learning.Course.Content.create_lesson(socket.assigns.course, params) do
      {:ok, lesson} ->
        {:noreply, stream_insert(socket, :lessons, lesson)}

      {:error, cs} ->
        {:noreply, assign(socket, form: to_form(cs))}
    end
  end

  def handle_event("validate", %{"lesson" => params}, socket) do
    cs = Learning.Course.Content.validate_lesson(socket.assigns.course, params)
    form = to_form(cs)
    {:noreply, assign(socket, form: form)}
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
