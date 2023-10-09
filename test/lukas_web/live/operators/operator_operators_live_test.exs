defmodule LukasWeb.Operator.OperatorsLiveTest do
  use LukasWeb.ConnCase

  alias Lukas.Accounts

  import Phoenix.LiveViewTest
  import Lukas.AccountsFixtures

  setup :register_and_log_in_user

  test "should render all operators in the system.", %{conn: conn} do
    1..50
    |> Enum.each(fn _ -> user_fixture() end)

    users = Accounts.list_operators()

    {:ok, lv, _html} = live(conn, ~p"/controls/operators")

    html = render_async(lv)

    Enum.each(users, fn user -> assert html =~ user.name end)
  end

  test "should react to operators registering.", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/controls/operators")

    1..50
    |> Enum.each(fn _ -> user_fixture() end)

    users = Accounts.list_operators()

    html = render_async(lv)
    Enum.each(users, fn user -> assert html =~ user.name end)
  end
end
