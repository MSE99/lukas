defmodule LukasWeb.StudentChannelTest do
  use LukasWeb.ChannelCase, async: true

  import Lukas.AccountsFixtures

  setup do
    user = student_fixture()
    token = Phoenix.Token.sign(LukasWeb.Endpoint, "channels api token", user.id)

    {:ok, socket} = connect(LukasWeb.StudentSocket, %{"token" => token})
    {:ok, _, joined_socket} = subscribe_and_join(socket, LukasWeb.StudentChannel, "student")

    %{socket: joined_socket, user: user, token: token}
  end

  describe "whoami event" do
    test "should return the currently connected student.", %{socket: socket, user: student} do
      ref = push(socket, "whoami", %{})
      expected = student |> Jason.encode!() |> Jason.decode!()

      assert_reply ref, :ok, ^expected
    end
  end
end
