defmodule LukasWeb.Shared.LecturerRegistrationLiveTest do
  use LukasWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lukas.AccountsFixtures

  setup do
    %{invite: invite_fixture()}
  end

  test "should redirect if the user is authenticated.", ctx do
    %{conn: conn} = register_and_log_in_user(ctx)
    assert {:error, {:redirect, _}} = live(conn, ~p"/register/foo")
  end

  test "form should render error on change.", %{conn: conn, invite: invite} do
    {:ok, lv, _} = live(conn, ~p"/register/#{invite.code}")

    render_result =
      lv
      |> form("form", %{
        "user" => valid_user_attributes() |> Map.delete(:kind) |> Map.delete(:phone_number)
      })
      |> render_change()

    assert render_result =~ "can&#39;t be blank"
  end

  test "form should render error on submit.", %{conn: conn, invite: invite} do
    {:ok, lv, _} = live(conn, ~p"/register/#{invite.code}")

    render_result =
      lv
      |> form("form", %{
        "user" => valid_user_attributes() |> Map.delete(:kind) |> Map.delete(:phone_number)
      })
      |> render_submit()

    assert render_result =~ "can&#39;t be blank"
  end

  test "form should create a new user on submit and redirect to login page.", %{
    conn: conn,
    invite: invite
  } do
    {:ok, lv, _} = live(conn, ~p"/register/#{invite.code}")

    lv
    |> form("form", %{
      "user" => valid_user_attributes() |> Map.delete(:kind)
    })
    |> render_submit()

    assert_redirected(lv, ~p"/users/log_in")
    assert Lukas.Accounts.list_invites() == []
  end
end
