defmodule LukasWeb.StudentChannelChannelTest do
  use LukasWeb.ChannelCase, async: true

  import Lukas.AccountsFixtures

  setup do
    student = student_fixture()
    token = Phoenix.Token.sign(LukasWeb.Endpoint, "student socket", student.id)

    {:ok, socket} = connect(LukasWeb.StudentSocket, %{"token" => token})
    {:ok, _, joined_socket} = subscribe_and_join(socket, LukasWeb.StudentChannel, "student")

    %{socket: joined_socket, user: student}
  end

  test "whoami event handler should serialize the send the user.", %{socket: socket, user: user} do
    ref = push(socket, "whoami", %{})
    assert_reply ref, :ok, body, 500
    assert body == user |> Jason.encode!() |> Jason.decode!()
  end
end
