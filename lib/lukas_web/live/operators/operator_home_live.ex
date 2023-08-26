defmodule LukasWeb.Operators.HomeLive do
  use LukasWeb, :live_view

  def mount(_, _, socket), do: {:ok, socket}

  def render(assigns) do
    ~H"""
    <h1>Operator's home</h1>

    <ul>
      <li>
        <.link navigate={~p"/controls/tags"}>Tags</.link>
        <.link navigate={~p"/controls/courses"}>Courses</.link>
      </li>
    </ul>
    """
  end
end
