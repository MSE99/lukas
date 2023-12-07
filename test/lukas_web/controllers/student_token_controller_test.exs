defmodule LukasWeb.StudentTokenControllerTest do
  use LukasWeb.ConnCase, async: true

  import Lukas.AccountsFixtures

  alias Lukas.Accounts

  describe "POST /api/log_in" do
    test "should respond with 403 if the user is authenticated.", ctx do
      %{conn: conn} = register_and_log_in_student(ctx)

      conn
      |> post(~p"/api/log_in", %{"phone_number" => "invalid", "password" => "invalid"})
      |> response(403)
    end

    test "should respond with 400 if the phone number is invalid.", %{conn: conn} do
      conn
      |> post(~p"/api/log_in", %{"phone_number" => "invalid", "password" => "invalid"})
      |> response(400)
    end

    test "should respond with 200 and the token if the phone number and username are valid.", %{
      conn: conn
    } do
      student = student_fixture()

      token =
        conn
        |> post(~p"/api/log_in", %{
          "phone_number" => student.phone_number,
          "password" => valid_user_password()
        })
        |> response(200)

      assert {:ok, ^student} = Accounts.fetch_student_by_api_token(token)
    end
  end

  describe "GET /api/whoami" do
    test "should respond with 401 if the user is not authenticated.", %{conn: conn} do
      conn
      |> get(~p"/api/whoami")
      |> response(401)
    end

    test "should respond with the student if the user is authenticated.", ctx do
      %{conn: conn, user: user} = register_and_log_in_student(ctx)

      body =
        conn
        |> get(~p"/api/whoami")
        |> json_response(200)

      assert body == user |> Jason.encode!() |> Jason.decode!()
    end
  end
end
