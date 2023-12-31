defmodule LukasWeb.Operator.CourseLive do
  use LukasWeb, :live_view

  alias Lukas.Learning
  alias Lukas.Money
  alias Lukas.Learning.Course

  alias LukasWeb.CommonComponents

  def mount(%{"id" => raw_id}, _session, socket) do
    with {id, _} <- Integer.parse(raw_id),
         {course, lecturers, course_tags} when course != nil <-
           Course.Staff.get_course_with_lecturers(id) do
      Learning.watch_course(course)
      Money.watch_course(course)

      profits = Money.calculate_course_profits(course.id)

      {:ok,
       socket
       |> assign(course: course)
       |> assign(profits: profits)
       |> load_lessons(course)
       |> stream(:lecturers, lecturers)
       |> stream(:course_tags, course_tags)}
    else
      _ -> {:ok, redirect(socket, to: ~p"/")}
    end
  end

  def handle_params(_, _, socket), do: {:noreply, socket}

  def load_lessons(socket, course), do: stream(socket, :lessons, Learning.get_lessons(course))

  def render(assigns) do
    ~H"""
    <CommonComponents.navigate_breadcrumbs links={[
      {~p"/controls", gettext("home")},
      {~p"/controls/courses", gettext("courses")},
      {~p"/controls/courses/#{@course.id}", @course.name}
    ]} />

    <CommonComponents.course_banner image_src={~p"/images/#{@course.banner_image}"} />

    <div class="mt-10 text-secondary px-2 pb-5">
      <h3 class="text-xl font-bold mb-3"><%= @course.name %></h3>

      <p class="mb-8 mt-5 ">
        <%= @course.description %>
      </p>

      <.link navigate={~p"/controls/courses/#{@course.id}/lessons"}>
        <CommonComponents.transparent_button>
          <.icon name="hero-book-open" class="me-2" /> <%= gettext("lessons") %>
        </CommonComponents.transparent_button>
      </.link>

      <.link navigate={~p"/controls/courses/#{@course.id}/settings"}>
        <CommonComponents.transparent_button>
          <.icon name="hero-cog-6-tooth" class="me-2" /> <%= gettext("settings") %>
        </CommonComponents.transparent_button>
      </.link>

      <.link navigate={~p"/controls/courses/#{@course.id}/enrollments"}>
        <CommonComponents.transparent_button>
          <.icon name="hero-academic-cap" class="me-2" /> <%= gettext("enrollments") %>
        </CommonComponents.transparent_button>
      </.link>

      <.link navigate={~p"/controls/courses/#{@course.id}/assign-lecturer"}>
        <CommonComponents.transparent_button>
          <.icon name="hero-sparkles" class="me-2" /> <%= gettext("lecturers") %>
        </CommonComponents.transparent_button>
      </.link>

      <.link>
        <CommonComponents.transparent_button>
          <.icon name="hero-currency-dollar" class="me-2" /> <%= gettext("profits") %> (<%= :erlang.float_to_binary(
            @profits,
            decimals: 2
          ) %> LYD)
        </CommonComponents.transparent_button>
      </.link>

      <CommonComponents.streamed_users_mini_list
        id="users-list"
        title={gettext("Lecturers")}
        users={@streams.lecturers}
      />

      <CommonComponents.streamed_tag_list
        id="tags-list"
        title={gettext("Tags")}
        tags={@streams.course_tags}
      />
    </div>

    <h3 class="mt-5 pb-5 font-bold text-primary">
      <%= gettext("Price") %> <%= :erlang.float_to_binary(@course.price, decimals: 1) %> LYD
    </h3>
    """
  end

  def handle_info({:course, _, :lecturer_added, lecturer}, socket) do
    {:noreply, stream_insert(socket, :lecturers, lecturer)}
  end

  def handle_info({:course, _, :lecturer_removed, lecturer}, socket) do
    {:noreply, stream_delete(socket, :lecturers, lecturer)}
  end

  def handle_info({:course, _, _, _}, socket), do: {:noreply, socket}

  def handle_info({:course_purchases, _, :purchase_made, purchase}, socket) do
    {:noreply, assign(socket, profits: socket.assigns.profits + purchase.amount)}
  end
end
