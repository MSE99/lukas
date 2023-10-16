defmodule LukasWeb.Lecturer.HomeLive do
  use LukasWeb, :live_view

  import LukasWeb.CommonComponents

  def mount(_, _, socket), do: {:ok, socket}

  def render(assigns) do
    ~H"""
    <.greeting>
      Hello <%= @current_user.name %>
    </.greeting>

    <ul class="flex flex-col gap-2 mt-5">
      <li>
        <.link class="bg-white shadow p-5 block max-w-xs" navigate={~p"/tutor/my-courses"}>
          <.icon name="hero-academic-cap-solid" class="mr-5" />My courses
        </.link>
      </li>
      <li>
        <.link class="bg-white shadow p-5 block max-w-xs" href={~p"/users/settings"}>
          <.icon name="hero-cog-6-tooth-solid" class="mr-5" />settings
        </.link>
      </li>
    </ul>

    <.link href={~p"/users/log_out"} method="DELETE" class="flex justify-end mt-5">
      <.danger_button>
        Logout
      </.danger_button>
    </.link>
    """
  end
end
