defmodule LukasWeb.Operators.HomeLive do
  use LukasWeb, :live_view

  import LukasWeb.CommonComponents

  def mount(_, _, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <.greeting>
      <%= gettext("Hello") %>
      <%= @current_user.name %>
    </.greeting>

    <ul class="flex flex-col gap-2 mt-5">
      <li>
        <.link navigate={~p"/controls/courses"} class="bg-white shadow p-5 block max-w-xs">
          <.icon name="hero-academic-cap-solid me-5" /> <%= gettext("Courses") %>
        </.link>
      </li>

      <li>
        <.link navigate={~p"/controls/lecturers"} class="bg-white shadow p-5 block max-w-xs">
          <.icon name="hero-academic-cap-solid me-5" /> <%= gettext("Lecturers") %>
        </.link>
      </li>

      <li>
        <.link navigate={~p"/controls/students"} class="bg-white shadow p-5 block max-w-xs">
          <.icon name="hero-academic-cap-solid me-5" /> <%= gettext("Students") %>
        </.link>
      </li>

      <li>
        <.link navigate={~p"/controls/operators"} class="bg-white shadow p-5 block max-w-xs">
          <.icon name="hero-academic-cap-solid me-5" /> <%= gettext("Operators") %>
        </.link>
      </li>

      <li>
        <.link navigate={~p"/controls/invites"} class="bg-white shadow p-5 block max-w-xs">
          <.icon name="hero-envelope-solid me-5" /> <%= gettext("Invites & staff") %>
        </.link>
      </li>

      <li>
        <.link navigate={~p"/controls/tags"} class="bg-white shadow p-5 block max-w-xs">
          <.icon name="hero-envelope-solid me-5" /> <%= gettext("Tags") %>
        </.link>
      </li>

      <li>
        <.link href={~p"/users/settings"} class="bg-white shadow p-5 block max-w-xs">
          <.icon name="hero-cog-6-tooth-solid me-5" /> <%= gettext("Settings") %>
        </.link>
      </li>
    </ul>

    <.link href={~p"/users/log_out"} method="DELETE" class="flex justify-end mt-5">
      <.danger_button>
        <%= gettext("Logout") %>
      </.danger_button>
    </.link>

    <.link href={~p"/locale"} method="patch">
      Switch locale :D
    </.link>
    """
  end
end
