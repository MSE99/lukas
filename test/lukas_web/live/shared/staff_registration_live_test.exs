defmodule LukasWeb.Shared.StaffRegistrationLiveTest do
  use LukasWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lukas.AccountsFixtures

  test "should redirect if the user is authenticated.", ctx do
    %{conn: conn} = register_and_log_in_user(ctx)
    assert {:error, {:redirect, _}} = live(conn, ~p"/register/foo")
  end

  describe "operator registration" do
    setup do
      %{invite: operator_invite_fixture()}
    end

    test "form should render error on change.", %{conn: conn, invite: invite} do
      {:ok, lv, _} = live(conn, ~p"/register/#{invite.code}")

      render_result =
        lv
        |> form("form", %{
          "user" => valid_user_attributes() |> Map.delete(:phone_number)
        })
        |> render_change()

      assert render_result =~ "can&#39;t be blank"
    end

    test "form should render error on submit.", %{conn: conn, invite: invite} do
      {:ok, lv, _} = live(conn, ~p"/register/#{invite.code}")

      render_result =
        lv
        |> form("form", %{
          "user" => valid_user_attributes() |> Map.delete(:phone_number)
        })
        |> render_submit()

      assert render_result =~ "can&#39;t be blank"
    end

    test "form should create a new user on submit and redirect to login page.", %{
      conn: conn,
      invite: invite
    } do
      {:ok, lv, _} = live(conn, ~p"/register/#{invite.code}")

      attrs = valid_user_attributes()

      lv
      |> form("form", %{
        "user" => attrs
      })
      |> render_submit()

      assert_redirected(lv, ~p"/log_in")

      [operator] = Lukas.Accounts.list_operators()

      assert Lukas.Accounts.list_invites() == []
      assert Lukas.Accounts.list_lecturers() == []
      assert Lukas.Accounts.list_students() == []

      assert operator.name == attrs.name
    end
  end

  describe "lecture registration" do
    setup do
      %{invite: lecturer_invite_fixture()}
    end

    test "form should render error on change.", %{conn: conn, invite: invite} do
      {:ok, lv, _} = live(conn, ~p"/register/#{invite.code}")

      render_result =
        lv
        |> form("form", %{
          "user" => valid_user_attributes() |> Map.delete(:phone_number)
        })
        |> render_change()

      assert render_result =~ "can&#39;t be blank"
    end

    test "form should render error on submit.", %{conn: conn, invite: invite} do
      {:ok, lv, _} = live(conn, ~p"/register/#{invite.code}")

      render_result =
        lv
        |> form("form", %{
          "user" => valid_user_attributes() |> Map.delete(:phone_number)
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
        "user" => valid_user_attributes()
      })
      |> render_submit()

      assert_redirected(lv, ~p"/log_in")
      assert Lukas.Accounts.list_invites() == []
    end
  end
end
