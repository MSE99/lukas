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

    <ul class="flex flex-col gap-2 mt-5">
      <li>
        <.link class="bg-white shadow p-5 block max-w-xs" navigate={~p"/tutor/my-courses"}>
          <.icon name="hero-academic-cap-solid" class="me-5" /><%= gettext("My courses") %>
        </.link>
      </li>
      <li>
        <.link class="bg-white shadow p-5 block max-w-xs" href={~p"/users/settings"}>
          <.icon name="hero-cog-6-tooth-solid" class="me-5" /><%= gettext("settings") %>
        </.link>
      </li>
    </ul>

    <.link href={~p"/users/log_out"} method="DELETE" class="flex justify-end mt-5">
      <.danger_button>
        <%= gettext("Logout") %>
      </.danger_button>
    </.link>

    <.link href={~p"/locale"} method="patch">
      <.icon name="hero-language" />
    </.link>
    """
  end
end
