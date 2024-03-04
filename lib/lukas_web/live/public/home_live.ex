defmodule LukasWeb.Public.HomeLive do
  use LukasWeb, :live_view

  alias Lukas.Learning

  alias Phoenix.LiveView.AsyncResult
  alias LukasWeb.CommonComponents

  def mount(_params, _session, socket) do
    next_socket =
      socket
      |> stream_configure(:latest_courses, [])
      |> stream_configure(:free_courses, [])
      |> assign(:loading, AsyncResult.loading())
      |> start_async(:loading, fn ->
        paid =
          Learning.list_courses(limit: 10, free: false)
          |> Enum.filter(fn course -> course.price > 0.0 end)

        free = Learning.list_courses(limit: 10, free: true)
        %{paid: paid, free: free}
      end)

    {:ok, next_socket}
  end

  def handle_async(:loading, {:ok, %{paid: paid, free: free}}, socket) do
    {:noreply,
     socket
     |> stream(:latest_courses, paid)
     |> stream(:free_courses, free)
     |> assign(:loading, AsyncResult.ok(socket.assigns.loading, nil))}
  end

  def handle_async(:loading, {:exit, reason}, socket) do
    {:noreply, assign(socket, :loading, AsyncResult.failed(socket.assigns.loading, reason))}
  end

  def render(assigns) do
    ~H"""
    <.async_result assign={@loading}>
      <:loading><.loading_spinner /></:loading>
      <:failed>Failed...</:failed>

      <div class="bg-primary-light w-full p-3 rounded-lg flex flex-col lg:flex-row gap-10">
        <div class="order-last lg:order-first">
          <h1 class="text-xl md:text-3xl font-bold mb-5">
            <%= gettext("Learn from the best teachers in Libya") %>
          </h1>

          <p class="mb-6 text-secondary">
            <%= gettext(
              "Lukas is an online platform for both educators to offer their content and students to learn."
            ) %>
          </p>

          <div class="flex">
            <CommonComponents.transparent_button>
              <.link navigate={~p"/log_in"}>
                <u><%= gettext("Sign in") %></u>
              </.link>
            </CommonComponents.transparent_button>

            <CommonComponents.transparent_button>
              <.link href={~p"/users/register"}><u><%= gettext("Register") %></u></.link>
            </CommonComponents.transparent_button>
          </div>
        </div>
      </div>

      <h3 class="font-bold text-secondary text-xl mb-10 mt-3 text-center">
        <%= gettext("Latest courses") %>
      </h3>

      <ul
        id="paid-courses"
        phx-update="stream"
        class="flex flex-wrap gap-5 justify-center md:justify-start"
      >
        <li :for={{id, course} <- @streams.latest_courses} id={id}>
          <.link class="hover:bg-gray-300" navigate={~p"/courses/#{course.id}"}>
            <CommonComponents.course_info
              course={course}
              banner_image_url={~p"/courses/#{course.id}/banner"}
            />
          </.link>
        </li>
      </ul>

      <h3 class="font-bold text-secondary text-xl mb-10 mt-10 text-center">
        <%= gettext("Free courses") %>
      </h3>

      <ul
        id="free-courses"
        phx-update="stream"
        class="flex flex-wrap gap-5 justify-center md:justify-start"
      >
        <li :for={{id, course} <- @streams.free_courses} id={id}>
          <.link class="hover:bg-gray-300" navigate={~p"/courses/#{course.id}"}>
            <CommonComponents.course_info
              course={course}
              banner_image_url={~p"/home/courses/#{course.id}/banner"}
            />
          </.link>
        </li>
      </ul>
    </.async_result>
    """
  end
end
