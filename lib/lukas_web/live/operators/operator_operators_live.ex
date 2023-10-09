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
        <li :for={{id, operator} <- @streams.operators} class={[!operator.enabled && "opacity-50", "transition-all"]} id={id}>
          <%= operator.name %> |
          <.button
            :if={operator.enabled}
            id={"disable-operator-#{operator.id}"}
            phx-click="disable-operator"
            phx-value-id={operator.id}
            phx-throttle
          >
            Disable operator
          </.button>

          <.button
            :if={!operator.enabled}
            id={"enable-operator-#{operator.id}"}
            phx-click="enable-operator"
            phx-value-id={operator.id}
            phx-throttle
          >
            Enable operator
          </.button>
        </li>
      </ul>
    </.async_result>
    """
  end

  def handle_event("disable-operator", %{"id" => raw_operator_id}, socket) do
    raw_operator_id
    |> String.to_integer()
    |> Accounts.get_operator()
    |> Accounts.disable_user()

    {:noreply, socket}
  end

  def handle_event("enable-operator", %{"id" => raw_operator_id}, socket) do
    raw_operator_id
    |> String.to_integer()
    |> Accounts.get_operator()
    |> Accounts.enable_user()

    {:noreply, socket}
  end

  def handle_info({:operators, :operator_registered, opr}, socket) do
    {:noreply, stream_insert(socket, :operators, opr)}
  end

  def handle_info({:operators, :operator_updated, opr}, socket) do
    {:noreply, stream_insert(socket, :operators, opr)}
  end
end
