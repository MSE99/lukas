defmodule LukasWeb.Shared.CourseLive do
  use LukasWeb, :live_view

  alias Lukas.Learning
  alias Lukas.Learning.Course.Staff

  alias LukasWeb.CommonComponents
  alias Phoenix.LiveView.AsyncResult

  def mount(%{"id" => raw_id}, _, socket) do
    with {id, _} <- Integer.parse(raw_id) do
      {:ok, begin_loading_course(socket, id)}
    else
      _ -> {:ok, redirect(socket, to: ~p"/")}
    end
  end

  defp begin_loading_course(socket, id) do
    socket
    |> assign(:loading, AsyncResult.loading())
    |> start_async(:loading, fn -> Staff.get_course_with_lecturers(id) end)
  end

  def handle_async(:loading, {:ok, {nil, _, _}}, socket) do
    {:noreply, redirect(socket, to: ~p"/")}
  end

  def handle_async(:loading, {:ok, {course, lecturers, tags}}, socket) do
    Learning.watch_course(course)

    next_socket =
      socket
      |> assign(:loading, AsyncResult.ok(socket.assigns.loading, nil))
      |> assign(:course, course)
      |> stream(:lecturers, lecturers)
      |> stream(:tags, tags)

    {:noreply, next_socket}
  end

  def handle_async(:loading, {:exit, reason}, socket) do
    {:noreply, assign(socket, loading: AsyncResult.failed(socket.assigns.loading, reason))}
  end

  def render(assigns) do
    ~H"""
    <.async_result assign={@loading}>
      <:loading>
        <CommonComponents.navigate_breadcrumbs links={[
          {~p"/", gettext("home")}
        ]} />

        <.loading_spinner />
      </:loading>

      <:failed>Failed to load course...</:failed>

      <CommonComponents.navigate_breadcrumbs links={[
        {~p"/", gettext("home")},
        {~p"/courses/#{@course.id}", @course.name}
      ]} />

      <CommonComponents.course_banner image_src={~p"/images/#{@course.banner_image}"} />

      <div class="mt-10 text-secondary px-2 pb-5">
        <h3 class="font-bold mb-3"><%= @course.name %></h3>

        <p class="mb-3">
          <%= @course.description %>
        </p>

        <div class="flex justify-end mt-8 mb-10">
          <CommonComponents.buy_button
            id="enroll-button"
            on_click={JS.navigate(~p"/log_in")}
            price={format_price(@course.price)}
          />
        </div>

        <CommonComponents.streamed_users_mini_list
          id="users-list"
          title={gettext("Lecturers")}
          users={@streams.lecturers}
        />

        <CommonComponents.streamed_tag_list
          id="tags-list"
          title={gettext("Tags")}
          tags={@streams.tags}
        />
      </div>
    </.async_result>
    """
  end

  defp format_price(amount), do: :erlang.float_to_binary(amount, decimals: 1)

  def handle_info({:course, _, :course_updated, next}, socket) do
    {:noreply, assign(socket, :course, next)}
  end

  def handle_info({:course, _, :lecturer_added, lect}, socket) do
    {:noreply, stream_insert(socket, :lecturers, lect)}
  end

  def handle_info({:course, _, :lecturer_removed, lect}, socket) do
    {:noreply, stream_delete(socket, :lecturers, lect)}
  end
end
