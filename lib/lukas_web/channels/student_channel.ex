defmodule LukasWeb.StudentChannel do
  use LukasWeb, :channel

  def join("student", _, socket) do
    {:ok, socket}
  end

  def handle_in("whoami", _, socket) do
    sanitized_student = socket.assigns.student |> Jason.encode!() |> Jason.decode!()
    {:reply, {:ok, sanitized_student}, socket}
  end
end
