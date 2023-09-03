defmodule LukasWeb.Students.HomeLive do
  use LukasWeb, :live_view

  def mount(_, _, socket), do: {:ok, socket}

  def render(assigns) do
    ~H"""
    <h1>Student's home</h1>

    <ul>
        <li>
          <.link navigate={~p"/home/courses"}>My courses</.link>
        </li>

        <li>
          <.link navigate={~p"/home/courses/available"}>Other courses</.link>
        </li>
    </ul>
    """
  end
end
