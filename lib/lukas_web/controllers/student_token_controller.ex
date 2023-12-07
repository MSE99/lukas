defmodule LukasWeb.StudentTokenController do
  use LukasWeb, :controller

  alias Lukas.Accounts

  def create(conn, %{"phone_number" => phone_number, "password" => password}) do
    if user = Accounts.get_user_by_phone_number_and_password(phone_number, password) do
      token = Accounts.create_student_api_token(user)

      conn
      |> put_resp_content_type("text/plain")
      |> resp(200, token)
    else
      conn
      |> send_resp(400, "Invalid phone number or password")
    end
  end

  def whoami(conn, _params) do
    %{current_user: current_user} = conn.assigns
    render(conn, :whoami, user: current_user)
  end

  def get_socket_token(conn, _params) do
    token = Phoenix.Token.sign(conn, "student socket", conn.assigns.current_user.id)

    conn
    |> put_resp_content_type("text/plain")
    |> resp(200, token)
  end
end
