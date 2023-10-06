defmodule LukasWeb.Students.WalletLive do
  use LukasWeb, :live_view

  alias Lukas.Money
  alias Phoenix.LiveView.AsyncResult

  def mount(_, _, socket) do
    if connected?(socket) do
      Money.watch_wallet(socket.assigns.current_user)
    end

    {:ok,
     socket
     |> assign(:wallet_amount, Money.get_deposited_amount!(socket.assigns.current_user))}
  end

  def render(assigns) do
    ~H"""
    <h1>Wallet</h1>
    <p><%= @wallet_amount |> format_amount() %> LYD</p>
    """
  end

  defp format_amount(amount), do: :erlang.float_to_binary(amount, decimals: 1)

  def handle_info({:wallet, _, :deposit_made, deposit}, socket) do
    {:noreply, update(socket, :wallet_amount, fn current -> deposit.amount + current end)}
  end
end
