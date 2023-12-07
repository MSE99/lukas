defmodule LukasWeb.StudentChannel do
  use LukasWeb, :channel

  def join("student", _, socket) do
    {:ok, socket}
  end

  def handle_in("whoami", _, socket) do
    student = socket.assigns.student |> Jason.encode!() |> Jason.decode!()
    {:reply, {:ok, student}, socket}
  end
end
