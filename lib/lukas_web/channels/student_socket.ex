defmodule LukasWeb.StudentSocket do
  use Phoenix.Socket

  alias Lukas.Accounts

  @impl true
  def connect(token, socket, _connect_info) do
    {:ok, student_id} =
      Phoenix.Token.verify(
        socket,
        "student socket",
        token,
        max_age: 86_400
      )

    student = Accounts.get_student!(student_id)
    {:ok, socket |> assign(:student, student)}
  end

  @impl true
  def id(socket), do: "students_socket:#{socket.assigns.student.id}"
end
