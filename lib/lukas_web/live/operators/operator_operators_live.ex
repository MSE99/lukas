defmodule LukasWeb.Operator.OperatorsLive do
  use LukasWeb, :live_view

  alias Lukas.Accounts
  alias Phoenix.LiveView.AsyncResult

  def mount(_, _, socket) do
    next_socket =
      socket
      |> stream_configure(:operators, [])
      |> assign(:loading, AsyncResult.loading())
      |> start_async(:loading, &Accounts.list_operators/0)

    {:ok, next_socket}
  end

  def handle_async(:loading, {:ok, operators}, socket) do
    Accounts.watch_operators()

    next_socket =
      socket
      |> assign(:loading, AsyncResult.ok(socket.assigns.loading, nil))
      |> stream(:operators, operators)

    {:noreply, next_socket}
  end

  def handle_async(:loading, {:exit, reason}, socket) do
    next_socket =
      socket
      |> assign(:loading, AsyncResult.failed(socket.assigns.loading, reason))

    {:noreply, next_socket}
  end

  def render(assigns) do
    ~H"""
    <.async_result assign={@loading}>
      <:loading>Loading operators...</:loading>
      <:failed>Failed...</:failed>

      <ul id="operators" phx-update="stream">
        <li :for={{id, operator} <- @streams.operators} id={id}>
          <%= operator.name %>
        </li>
      </ul>
    </.async_result>
    """
  end

  def handle_info({:operators, :operator_registered, opr}, socket) do
    {:noreply, stream_insert(socket, :operators, opr)}
  end
end
