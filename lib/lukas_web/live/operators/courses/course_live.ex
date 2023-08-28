defmodule LukasWeb.Operator.CourseLive do
  use LukasWeb, :live_view

  alias Lukas.Learning

  def mount(%{"id" => raw_id}, _session, socket) do
    with {id, _} <- Integer.parse(raw_id), course when course != nil <- Learning.get_course(id) do
      {:ok, socket |> assign(course: course)}
    else
      _ -> {:ok, redirect(socket, to: ~p"/")}
    end
  end

  def load_lessons(socket, course), do: stream(socket, :lessons, Learning.get_lessons(course))

  def render(assigns) do
    ~H"""
      <h1>Course <%= @course.name %></h1>

      <ul></ul>
    """
  end
end
