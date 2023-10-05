defmodule LukasWeb.Operators.HomeLive do
  use LukasWeb, :live_view

  import LukasWeb.CommonComponents

  def mount(_, _, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <.basic_navbar />

    <.profile_card user={@current_user} />

    <ul class="flex flex-col items-center">
      <li class="w-full max-w-sm mb-2">
        <.link class="block rounded w-full bg-white p-5 shadow" navigate={~p"/controls/courses"}>
          <.icon name="hero-academic-cap-solid mr-5" /> Courses & students
        </.link>
      </li>

      <li class="w-full max-w-sm mb-2">
        <.link class="block rounded w-full bg-white p-5 shadow" navigate={~p"/controls/invites"}>
          <.icon name="hero-envelope-solid mr-5" /> Invites & staff
        </.link>
      </li>

      <li class="max-w-sm w-full flex justify-center items-center mb-2">
        <.link class="block rounded w-full bg-white p-5 shadow" href={~p"/users/settings"}>
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
