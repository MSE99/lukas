defmodule LukasWeb.Lecturer.HomeLive do
  use LukasWeb, :live_view

  import LukasWeb.CommonComponents

  def mount(_, _, socket), do: {:ok, socket}

  def render(assigns) do
    ~H"""
    <.greeting>
      <%= gettext("Hello") %>
      <%= @current_user.name %>
    </.greeting>
    <ul class="flex flex-col w-full gap-2 mt-5 justify-center md:justify-start">
      <li class="max-w-xs w-full h-full">
        <.link
          navigate={~p"/tutor/my-courses"}
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
          navigate={~p"/users/settings"}
          class="bg-white shadow rounded-lg h-28 hover:outline outline-purple-300 transition-all transition-100 p-5 flex flex-col max-w-xs"
        >
          <div class="flex items-center">
            <.icon name="hero-cog-solid me-3" /> <%= gettext("Settings") %>
          </div>

          <p class="mt-3 text-sm text-secondary">
            <%= gettext("Update your accounts settings.") %>
          </p>
        </.link>
      </li>
    </ul>

    <div class="flex mt-5 flex-col items-end gap-10">
      <.link href={~p"/users/log_out"} method="DELETE">
        <.danger_button>
          <%= gettext("Logout") %>
        </.danger_button>
      </.link>

      <.link href={~p"/locale"} method="patch">
        <.icon name="hero-language" />
      </.link>
    </div>
    """
  end
end
