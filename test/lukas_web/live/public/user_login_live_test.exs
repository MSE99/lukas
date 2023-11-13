defmodule LukasWeb.UserLoginLiveTest do
  use LukasWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Lukas.AccountsFixtures

  describe "Log in page" do
    test "renders log in page", %{conn: conn} do
      assert {:ok, _lv, _html} = live(conn, ~p"/log_in")
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/log_in")
        |> follow_redirect(conn, ~p"/controls")

      assert {:ok, _conn} = result
    end
  end

  describe "user login" do
    test "redirects if user login with valid credentials", %{conn: conn} do
      password = "123456789abcd"
      user = user_fixture(%{password: password})

      {:ok, lv, _html} = live(conn, ~p"/log_in")

      form =
        form(lv, "#login_form",
          user: %{phone_number: user.phone_number, password: password, remember_me: true}
        )

      conn = submit_form(form, conn)

      assert redirected_to(conn) == ~p"/controls"
    end

    test "redirects to login page with a flash error if there are no valid credentials", %{
      conn: conn
    } do
      {:ok, lv, _html} = live(conn, ~p"/log_in")

      form =
        form(
          lv,
          "#login_form",
          user: %{phone_number: "test@email.com", password: "123456", remember_me: true}
        )

      conn = submit_form(form, conn)

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid phone number or password"

      assert redirected_to(conn) == ~p"/log_in"
    end
  end
end
