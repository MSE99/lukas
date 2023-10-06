defmodule LukasWeb.Students.WalletLiveTest do
  use LukasWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lukas.MoneyFixtures
  import Lukas.AccountsFixtures

  setup :register_and_log_in_student

  test "should render 0 LYD.", %{conn: conn} do
    {:ok, lv, _} = live(conn, ~p"/home/wallet")
    assert render_async(lv) =~ "0.0 LYD"
  end

  test "should render 1500 LYD.", %{conn: conn, user: user} do
    clerk = user_fixture()

    direct_deposit_fixture(clerk, user, 1500)

    {:ok, lv, _} = live(conn, ~p"/home/wallet")

    assert render_async(lv) =~ "1500.0 LYD"
  end

  test "should react to deposits being created.", %{conn: conn, user: user} do
    {:ok, lv, _} = live(conn, ~p"/home/wallet")

    clerk = user_fixture()

    Enum.each(1..10, fn _ -> direct_deposit_fixture(clerk, user, 100) end)

    assert render_async(lv) =~ "1000.0 LYD"
  end
end
