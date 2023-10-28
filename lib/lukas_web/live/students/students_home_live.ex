defmodule LukasWeb.Students.HomeLive do
  use LukasWeb, :live_view

  def mount(_, _, socket), do: {:ok, socket}

  def render(assigns) do
    ~H"""
    <h1 class="text-lg mb-5 mt-16">
      Hello <%= @current_user.name %>
    </h1>

    <ul class="flex flex-col gap-2">
      <li>
        <.link class="bg-white shadow p-5 block max-w-xs" navigate={~p"/home/courses"}>
          <.icon name="hero-academic-cap-solid" class="me-5" /><%= gettext("My courses") %>
        </.link>
      </li>

      <li>
        <.link class="bg-white shadow p-5 block max-w-xs" navigate={~p"/home/courses/available"}>
          <.icon name="hero-academic-cap-solid" class="me-5" /><%= gettext("Other courses") %>
        </.link>
      </li>

      <li>
        <.link class="bg-white shadow p-5 block max-w-xs" navigate={~p"/home/wallet"}>
          <.icon name="hero-envelope-solid" class="me-5" /><%= gettext("My wallet") %>
        </.link>
      </li>

      <li>
        <.link class="bg-white shadow p-5 block max-w-xs" href={~p"/users/settings"}>
          <.icon name="hero-cog-6-tooth-solid" class="me-5" /><%= gettext("settings") %>
        </.link>
      </li>
    </ul>

    <.link method="DELETE" href={~p"/users/log_out"}>
      <.button>
        <%= gettext("Logout") %>
      </.button>
    </.link>

    <.link method="patch" href={~p"/locale"}>
      Switch locale
    </.link>
    """
  end
end
