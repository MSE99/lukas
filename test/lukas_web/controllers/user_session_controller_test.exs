defmodule LukasWeb.UserSessionControllerTest do
  use LukasWeb.ConnCase, async: true

  import Lukas.AccountsFixtures

  setup do
    %{user: user_fixture()}
  end

  describe "POST /users/log_in" do
    test "logs the operator in", %{conn: conn} do
      user = user_fixture(%{kind: :operator})

      conn =
        post(conn, ~p"/users/log_in", %{
          "user" => %{"phone_number" => user.phone_number, "password" => valid_user_password()}
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == ~p"/controls"
    end

    test "logs the user in with remember me", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/users/log_in", %{
          "user" => %{
            "phone_number" => user.phone_number,
            "password" => valid_user_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_lukas_web_user_remember_me"]
      assert redirected_to(conn) == ~p"/controls"
    end

    test "logs the user in with return to", %{conn: conn, user: user} do
      conn =
        conn
        |> init_test_session(user_return_to: "/foo/bar")
        |> post(~p"/users/log_in", %{
          "user" => %{
            "phone_number" => user.phone_number,
            "password" => valid_user_password()
          }
        })

      assert redirected_to(conn) == "/foo/bar"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Welcome back!"
    end

    test "login following registration", %{conn: conn, user: user} do
      conn =
        conn
        |> post(~p"/users/log_in", %{
          "_action" => "registered",
          "user" => %{
            "phone_number" => user.phone_number,
            "password" => valid_user_password()
          }
        })

      assert redirected_to(conn) == ~p"/controls"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Account created successfully"
    end

    test "login following password update", %{conn: conn, user: user} do
      conn =
        conn
        |> post(~p"/users/log_in", %{
          "_action" => "password_updated",
          "user" => %{
            "phone_number" => user.phone_number,
            "password" => valid_user_password()
          }
        })

      assert redirected_to(conn) == ~p"/users/settings"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Password updated successfully"
    end

    test "redirects to login page with invalid credentials", %{conn: conn} do
      conn =
        post(conn, ~p"/users/log_in", %{
          "user" => %{"phone_number" => "invalid@email.com", "password" => "invalid_password"}
        })

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid phone number or password"
      assert redirected_to(conn) == ~p"/log_in"
    end
  end

  describe "DELETE /users/log_out" do
    test "logs the user out", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user) |> delete(~p"/users/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the user is not logged in", %{conn: conn} do
      conn = delete(conn, ~p"/users/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end
  end

  describe "GET /api/whoami" do
    test "should respond with 401 if the user is not authenticated.", %{conn: conn} do
      conn
      |> get(~p"/api/whoami")
      |> response(401)
    end

    test "should respond with the current user without the password or password_hash props.", %{
      conn: conn,
      user: user
    } do
      resp_body =
        conn
        |> log_in_user(user)
        |> get(~p"/api/whoami")
        |> json_response(200)

      assert resp_body == user |> Jason.encode!() |> Jason.decode!()
    end
  end

  describe "GET /api/token" do
    test "should respond with 401 if the user is not authenticated.", %{conn: conn} do
      conn
      |> get(~p"/api/tokens")
      |> response(401)
    end

    test "should respond 200 and the token as the request body.", %{conn: conn, user: user} do
      body =
        conn
        |> log_in_user(user)
        |> get(~p"/api/tokens")
        |> response(200)

      {:ok, user_id} = Phoenix.Token.verify(LukasWeb.Endpoint, "channels api token", body)

      assert user_id == user.id
    end
  end
end
