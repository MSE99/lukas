defmodule LukasWeb.UserSessionController do
  use LukasWeb, :controller

  alias Lukas.Accounts
  alias LukasWeb.UserAuth

  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, "Account created successfully!")
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:user_return_to, ~p"/users/settings")
    |> create(params, "Password updated successfully!")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  defp create(conn, %{"user" => user_params}, info) do
    %{"phone_number" => phone_number, "password" => password} = user_params

    if user = Accounts.get_user_by_phone_number_and_password(phone_number, password) do
      conn
      |> put_flash(:info, info)
      |> UserAuth.log_in_user(user, user_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the phone_number is registered.
      conn
      |> put_flash(:error, "Invalid phone number or password")
      |> put_flash(:phone_number, String.slice(phone_number, 0, 160))
      |> redirect(to: ~p"/log_in")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end

  def whoami(conn, _params) do
    if conn.assigns[:current_user] == nil do
      conn |> resp(401, "Unauthorized") |> send_resp()
    else
      render(conn, :whoami, user: conn.assigns.current_user)
    end
  end
end
