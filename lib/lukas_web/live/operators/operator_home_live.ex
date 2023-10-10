defmodule LukasWeb.Operators.HomeLive do
  use LukasWeb, :live_view

  import LukasWeb.CommonComponents

  def mount(_, _, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <ul>
      <li>
        <.link navigate={~p"/controls/courses"}>
          <.icon name="hero-academic-cap-solid mr-5" /> Courses & students
        </.link>
      </li>

      <li>
        <.link navigate={~p"/controls/lecturers"}>
          <.icon name="hero-academic-cap-solid mr-5" /> Lecturers
        </.link>
      </li>

      <li>
        <.link navigate={~p"/controls/students"}>
          <.icon name="hero-academic-cap-solid mr-5" /> Students
        </.link>
      </li>

      <li>
        <.link navigate={~p"/controls/invites"}>
          <.icon name="hero-envelope-solid mr-5" /> Invites & staff
        </.link>
      </li>

      <li>
        <.link href={~p"/users/settings"}>
          <.icon name="hero-cog-6-tooth-solid mr-5" /> Settings
        </.link>
      </li>
    </ul>

    <.link
      href={~p"/users/log_out"}
      method="DELETE"
      class="flex justify-center max-w-fit mx-auto mt-5"
    >
      <.danger_button>
        Logout
      </.danger_button>
    </.link>
    """
  end
end
