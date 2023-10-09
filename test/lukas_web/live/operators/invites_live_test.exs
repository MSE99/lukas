defmodule LukasWeb.Operator.InvitesLiveTest do
  use LukasWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lukas.AccountsFixtures

  alias Lukas.Accounts

  test "should require an authenticated operator.", %{conn: conn} do
    assert {:error, {:redirect, _}} = live(conn, ~p"/controls/invites")
  end

  describe "index" do
    setup [:register_and_log_in_user]

    test "should render all invites", %{conn: conn} do
      inv1 = lecturer_invite_fixture()
      inv2 = lecturer_invite_fixture()
      inv3 = lecturer_invite_fixture()

      {:ok, lv, _html} = live(conn, ~p"/controls/invites")

      html = render_async(lv)

      assert html =~ inv1.code
      assert html =~ inv2.code
      assert html =~ inv3.code
    end

    test "should react to invites being added", %{conn: conn} do
      {:ok, lv, _} = live(conn, ~p"/controls/invites")

      inv1 = lecturer_invite_fixture()
      inv2 = lecturer_invite_fixture()
      inv3 = lecturer_invite_fixture()

      html = render_async(lv)

      assert html =~ inv1.code
      assert html =~ inv2.code
      assert html =~ inv3.code
    end

    test "clicking delete should delete the invite", %{conn: conn} do
      {:ok, lv, _} = live(conn, ~p"/controls/invites")

      inv1 = lecturer_invite_fixture()
      inv2 = lecturer_invite_fixture()
      inv3 = lecturer_invite_fixture()

      render_async(lv)

      lv |> element(".delete-invite-button[phx-value-id=\"#{inv1.id}\"]") |> render_click()

      refute render(lv) =~ inv1.code
      assert render(lv) =~ inv2.code
      assert render(lv) =~ inv3.code
    end

    test "clicking on generate button should generate a new invite.", %{conn: conn} do
      {:ok, lv, _} = live(conn, ~p"/controls/invites")

      render_async(lv)

      lv |> element("#generate-invite-button") |> render_click()

      [invite] = Accounts.list_invites()

      assert render(lv) =~ invite.code
    end
  end
end
