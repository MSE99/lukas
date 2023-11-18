defmodule LukasWeb.Students.HomeLive do
  use LukasWeb, :live_view

  alias LukasWeb.CommonComponents

  def mount(_, _, socket), do: {:ok, socket}

  def render(assigns) do
    ~H"""
    <CommonComponents.greeting>
      <%= gettext("Hello") %>
      <%= @current_user.name %>
    </CommonComponents.greeting>

    <ul class="flex flex-col w-full gap-2 mt-5 justify-center md:justify-start">
      <li class="max-w-xs w-full h-full">
        <.link
          navigate={~p"/home/courses"}
          class="bg-white shadow rounded-lg h-28 hover:outline outline-green-300 transition-all transition-100 p-5 flex flex-col max-w-xs"
        >
          <div class="flex items-center">
            <.icon name="hero-academic-cap-solid me-3" /> <%= gettext("My courses") %>
          </div>

          <p class="mt-3 text-sm text-secondary">
            <%= gettext("View all courses on your platform or add new ones.") %>
          </p>
        </.link>
      </li>

      <li class="max-w-xs w-full h-full">
        <.link
          navigate={~p"/users/settings"}
          class="bg-white shadow rounded-lg h-28 hover:outline outline-green-300 transition-all transition-100 p-5 flex flex-col max-w-xs"
        >
          <div class="flex items-center">
            <.icon name="hero-cog-solid me-3" /> <%= gettext("Settings") %>
          </div>

          <p class="mt-3 text-sm text-secondary">
            <%= gettext("Update your accounts settings.") %>
          </p>
        </.link>
      </li>

      <li class="max-w-xs w-full h-full">
        <.link
          navigate={~p"/home/courses/available"}
          class="bg-white shadow rounded-lg h-28 hover:outline outline-green-300 transition-all transition-100 p-5 flex flex-col max-w-xs"
        >
          <div class="flex items-center">
            <.icon name="hero-academic-cap-solid" class="me-3" /> <%= gettext("Other courses") %>
          </div>

          <p class="mt-3 text-sm text-secondary">
            <%= gettext("Update your accounts settings.") %>
          </p>
        </.link>
      </li>

      <li class="max-w-xs w-full h-full">
        <.link
          navigate={~p"/home/wallet"}
          class="bg-white shadow rounded-lg h-28 hover:outline outline-green-300 transition-all transition-100 p-5 flex flex-col max-w-xs"
        >
          <div class="flex items-center">
            <.icon name="hero-envelope-solid" class="me-3" /> <%= gettext("My wallet") %>
          </div>

          <p class="mt-3 text-sm text-secondary">
            <%= gettext("View your funds and transactions.") %>
          </p>
        </.link>
      </li>
    </ul>

    <div class="flex flex-col gap-10 mt-5">
      <.link method="DELETE" href={~p"/users/log_out"}>
        <.button>
          <%= gettext("Logout") %>
        </.button>
      </.link>

      <.link href={~p"/locale"} method="patch">
        <.icon name="hero-language" />
      </.link>
    </div>
    """
  end
end
