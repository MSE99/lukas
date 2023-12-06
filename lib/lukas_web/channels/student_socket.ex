defmodule LukasWeb.StudentSocket do
  use Phoenix.Socket

  alias Lukas.Accounts

  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    {:ok, user_id} = Phoenix.Token.verify(socket, "channels api token", token, max_age: 86400)
    student = Accounts.get_student!(user_id)
    {:ok, assign(socket, :student, student)}
  end

  @impl true
  def id(_socket), do: nil
end
