defmodule LukasWeb.Operator.StudentsLive do
  use LukasWeb, :live_view

  alias Phoenix.LiveView.AsyncResult
  alias Lukas.Accounts

  def mount(_, _, socket) do
    next_socket =
      socket
      |> stream_configure(:students, [])
      |> assign(:loading, AsyncResult.loading())
      |> start_async(:loading, fn ->
        Accounts.list_students()
      end)

    {:ok, next_socket}
  end

  def handle_async(:loading, {:ok, students}, socket) do
    Accounts.watch_students()

    {:noreply,
     socket
     |> assign(loading: AsyncResult.ok(socket.assigns.loading, nil))
     |> stream(:students, students)}
  end

  def handle_async(:loading, {:exit, reason}, socket) do
    {:noreply, assign(socket, loading: AsyncResult.failed(socket.assigns.loading, reason))}
  end

  def render(assigns) do
    ~H"""
    <h1>Students</h1>

    <.async_result assign={@loading}>
      <:loading>Loading students...</:loading>
      <:failed>Failed to load students</:failed>

      <ul id="students" phx-update="stream">
        <li :for={{id, student} <- @streams.students} id={id}>
          <%= student.name %>
        </li>
      </ul>
    </.async_result>
    """
  end

  def handle_info({:students, :student_registered, student}, socket) do
    {:noreply, socket |> stream_insert(:students, student)}
  end
end
