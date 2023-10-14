defmodule LukasWeb.Students.CourseLive do
  use LukasWeb, :live_view

  alias Lukas.Money
  alias Lukas.Learning
  alias Lukas.Learning.Course.Students

  alias LukasWeb.CommonComponents

  def mount(%{"id" => raw_course_id}, _session, socket) do
    with {id, _} <- Integer.parse(raw_course_id),
         {course, lect, tags, is_enrolled} when course != nil <-
           Learning.get_course_for_student(id, socket.assigns.current_user) do
      Learning.watch_course(id)
      Money.watch_wallet(socket.assigns.current_user)

      wallet_amount = Money.get_deposited_amount!(socket.assigns.current_user)

      {:ok,
       socket
       |> assign(course: course)
       |> assign(is_enrolled: is_enrolled)
       |> assign(wallet_amount: wallet_amount)
       |> stream(:lecturers, lect)
       |> stream(:tags, tags)}
    else
      _ -> {:ok, redirect(socket, to: ~p"/home/courses")}
    end
  end

  def handle_params(_, _, socket), do: {:noreply, socket}

  def render(assigns) do
    ~H"""
    <CommonComponents.navigate_breadcrumbs links={[
      {~p"/home", "home"},
      {~p"/home/courses", "courses"},
      {~p"/home/courses/#{@course.id}", @course.name}
    ]} />

    <CommonComponents.course_banner image_src={~p"/images/#{@course.banner_image}"} />

    <div class="mt-10 text-secondary px-2 pb-5">
      <h3 class="font-bold mb-3"><%= @course.name %></h3>

      <p class="mb-3">
        Lorem ipsum dolor sit amet consectetur, adipisicing elit. Cumque recusandae odio, veritatis asperiores eum eveniet et dolorum, temporibus debitis sed ex culpa, amet saepe maxime ratione ullam eaque doloribus reiciendis?
      </p>

      <.link
        :if={@is_enrolled}
        class="font-bold underline"
        navigate={~p"/home/courses/#{@course.id}/study"}
      >
        Open lessons  »
      </.link>

      <div :if={!@is_enrolled && @wallet_amount >= @course.price} class="flex justify-end mt-8 mb-10">
        <CommonComponents.buy_button
          id="enroll-button"
          on_click="enroll"
          price={format_price(@course.price)}
        />
      </div>

      <CommonComponents.streamed_users_mini_list
        id="users-list"
        title="Lecturers"
        users={@streams.lecturers}
      />

      <CommonComponents.streamed_tag_list id="tags-list" title="Tags" tags={@streams.tags} />
    </div>
    """
  end

  def handle_event("enroll", _params, socket) do
    {:ok, _} = Students.enroll_student(socket.assigns.course, socket.assigns.current_user)
    {:noreply, push_patch(socket, to: ~p"/home/courses/#{socket.assigns.course.id}")}
  end

  def handle_info({:course, _, :course_updated, course}, socket) do
    {:noreply, assign(socket, course: course)}
  end

  def handle_info({:course, _, :lecturer_added, lecturer}, socket) do
    {:noreply, stream_insert(socket, :lecturers, lecturer)}
  end

  def handle_info({:course, _, :lecturer_removed, lecturer}, socket) do
    {:noreply, stream_delete(socket, :lecturers, lecturer)}
  end

  def handle_info({:course, _, :course_tagged, tag}, socket) do
    {:noreply, stream_insert(socket, :tags, tag)}
  end

  def handle_info({:course, _, :course_untagged, tag}, socket) do
    {:noreply, stream_delete(socket, :tags, tag)}
  end

  def handle_info({:course, _, :student_enrolled, student}, socket)
      when student.id == socket.assigns.current_user.id do
    {:noreply, assign(socket, is_enrolled: true)}
  end

  def handle_info({:course, _, _, _}, socket), do: {:noreply, socket}

  def handle_info({:wallet, _, :amount_updated, next_amount}, socket) do
    {:noreply, assign(socket, wallet_amount: next_amount)}
  end

  defp format_price(p), do: :erlang.float_to_binary(p, decimals: 1)
end
