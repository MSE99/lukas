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

    <ul class="flex flex-wrap w-full gap-2 mt-5 justify-center md:justify-start">
      <li class="max-w-xs w-full h-full">
        <.link
          navigate={~p"/controls/courses"}
          class="bg-white shadow rounded-lg h-28 hover:outline outline-purple-300 transition-all transition-100 p-5 flex flex-col max-w-xs"
        >
          <div class="flex items-center">
            <.icon name="hero-academic-cap-solid me-3" /> <%= gettext("Courses") %>
          </div>

          <p class="mt-3 text-sm text-secondary">
            <%= gettext("View all courses on your platform or add new ones.") %>
          </p>
        </.link>
      </li>

      <li class="max-w-xs w-full h-full">
        <.link
          navigate={~p"/controls/stats"}
          class="bg-white shadow rounded-lg h-28 hover:outline outline-purple-300 transition-all transition-100 p-5 flex flex-col max-w-xs"
        >
          <div class="flex items-center">
            <.icon name="hero-chart-pie-solid me-3" /> <%= gettext("Statistics") %>
          </div>

          <p class="mt-3 text-sm text-secondary">
            <%= gettext("Read the latest stats and see how your platform is performing.") %>
          </p>
        </.link>
      </li>

      <li class="max-w-xs w-full h-full">
        <.link
          navigate={~p"/controls/lecturers"}
          class="bg-white shadow rounded-lg h-28 hover:outline outline-purple-300 transition-all transition-100 p-5 flex flex-col max-w-xs"
        >
          <div class="flex items-center">
            <.icon name="hero-user-circle-solid me-3" /> <%= gettext("Lecturers") %>
          </div>

          <p class="mt-3 text-sm text-secondary">
            <%= gettext("View all lecturers on your platform or add new ones.") %>
          </p>
        </.link>
      </li>

      <li class="max-w-xs w-full h-full">
        <.link
          navigate={~p"/controls/students"}
          class="bg-white shadow rounded-lg h-28 hover:outline outline-purple-300 transition-all transition-100 p-5 flex flex-col max-w-xs"
        >
          <div class="flex items-center">
            <.icon name="hero-users-solid me-3" /> <%= gettext("Students") %>
          </div>

          <p class="mt-3 text-sm text-secondary">
            <%= gettext("View all students on your platform or add new ones.") %>
          </p>
        </.link>
      </li>

      <li class="max-w-xs w-full h-full">
        <.link
          navigate={~p"/controls/operators"}
          class="bg-white shadow rounded-lg h-28 hover:outline outline-purple-300 transition-all transition-100 p-5 flex flex-col max-w-xs"
        >
          <div class="flex items-center">
            <.icon name="hero-cursor-arrow-ripple-solid me-3" /> <%= gettext("Operators") %>
          </div>

          <p class="mt-3 text-sm text-secondary">
            <%= gettext("View all operators on your platform or add new ones.") %>
          </p>
        </.link>
      </li>

      <li class="max-w-xs w-full h-full">
        <.link
          navigate={~p"/controls/invites"}
          class="bg-white shadow rounded-lg h-28 hover:outline outline-purple-300 transition-all transition-100 p-5 flex flex-col max-w-xs"
        >
          <div class="flex items-center">
            <.icon name="hero-envelope-solid me-3" /> <%= gettext("Invites") %>
          </div>

          <p class="mt-3 text-sm text-secondary">
            <%= gettext("Invite operators/lecturers to your platform.") %>
          </p>
        </.link>
      </li>

      <li class="max-w-xs w-full h-full">
        <.link
          navigate={~p"/controls/tags"}
          class="bg-white shadow rounded-lg h-28 hover:outline outline-purple-300 transition-all transition-100 p-5 flex flex-col max-w-xs"
        >
          <div class="flex items-center">
            <.icon name="hero-tag-solid me-3" /> <%= gettext("Tags") %>
          </div>

          <p class="mt-3 text-sm text-secondary">
            <%= gettext("View all tags on your platform or add new ones.") %>
          </p>
        </.link>
      </li>

      <li class="max-w-xs w-full h-full">
        <.link
          href={~p"/users/settings"}
          class="bg-white shadow rounded-lg h-28 hover:outline outline-purple-300 transition-all transition-100 p-5 flex flex-col max-w-xs"
        >
          <div class="flex items-center">
            <.icon name="hero-cog-6-tooth-solid me-3" /> <%= gettext("Settings") %>
          </div>

          <p class="mt-3 text-sm text-secondary">
            <%= gettext("Your accounts settings.") %>
          </p>
        </.link>
      </li>

      <li class="max-w-xs w-full h-full">
        <.link
          href={~p"/controls/cards"}
          class="bg-white shadow rounded-lg h-28 hover:outline outline-purple-300 transition-all transition-100 p-5 flex flex-col max-w-xs"
        >
          <div class="flex items-center">
            <.icon name="hero-currency-dollar-solid me-3" /> <%= gettext("Cards") %>
          </div>

          <p class="mt-3 text-sm text-secondary">
            <%= gettext("Credit cards for your platform.") %>
          </p>
        </.link>
      </li>
    </ul>

    <div class="flex justify-end my-5">
      <.link href={~p"/users/log_out"} method="DELETE">
        <.danger_button>
          <%= gettext("Logout") %>
        </.danger_button>
      </.link>
    </div>

    <.link href={~p"/locale"} method="patch">
      <.icon name="hero-language" />
    </.link>
    """
  end
end
