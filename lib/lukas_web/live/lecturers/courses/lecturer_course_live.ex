defmodule LukasWeb.Lecturer.CourseLive do
  use LukasWeb, :live_view

  alias Lukas.Learning
  alias Lukas.Learning.Course

  alias LukasWeb.CommonComponents

  def mount(%{"id" => raw_id}, _session, socket) do
    with {id, _} <- Integer.parse(raw_id),
         {course, lecturers, tags} when course != nil <-
           Course.Staff.get_course_with_lecturers(id),
         current_lect when current_lect != nil <-
           Enum.find(lecturers, fn lect -> lect.id == socket.assigns.current_user.id end) do
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

  def handle_params(_, _, socket), do: {:noreply, socket}

  def load_lessons(socket, course), do: stream(socket, :lessons, Learning.get_lessons(course))

  def render(assigns) do
    ~H"""
    <CommonComponents.navigate_breadcrumbs links={[
      {~p"/tutor", gettext("home")},
      {~p"/tutor/my-courses", gettext("my courses")},
      {~p"/tutor/my-courses/#{@course.id}", @course.name}
    ]} />

    <CommonComponents.course_banner image_src={~p"/tutor/my-courses/#{@course.id}/banner"} />

    <div class="mt-10 text-secondary px-2 pb-5">
      <h3 class="text-xl font-bold mb-3"><%= @course.name %></h3>

      <p class="mb-8 mt-5 ">
        <%= @course.description %>
      </p>

      <.link navigate={~p"/tutor/my-courses/#{@course.id}/lessons"}>
        <CommonComponents.transparent_button>
          <.icon name="hero-book-open" class="me-2" /> <%= gettext("Lessons") %>
        </CommonComponents.transparent_button>
      </.link>

      <.link navigate={~p"/tutor/my-courses/#{@course.id}/settings"}>
        <CommonComponents.transparent_button>
          <.icon name="hero-cog-6-tooth" class="me-2" /> <%= gettext("settings") %>
        </CommonComponents.transparent_button>
      </.link>

      <CommonComponents.streamed_users_mini_list
        id="users-list"
        title={gettext("Lecturers")}
        users={@streams.lecturers}
      />

      <CommonComponents.streamed_tag_list id="tags-list" title={gettext("Tags")} tags={@streams.tags} />
    </div>

    <h3 class="mt-5 pb-5 font-bold text-primary">
      Price <%= :erlang.float_to_binary(@course.price, decimals: 2) %> LYD
    </h3>
    """
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

  def handle_info({:course, _, _, _}, socket) do
    {:noreply, socket}
  end
end
