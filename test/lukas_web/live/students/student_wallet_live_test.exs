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
    clerk = user_fixture()

    deposits = Enum.map(1..10, fn _ -> direct_deposit_fixture(clerk, user, 100) end)

    {:ok, lv, _} = live(conn, ~p"/home/wallet")

    html = render_async(lv)

    assert html =~ "1000.0 LYD"

    Enum.each(deposits, fn d ->
      assert lv |> element("#tx-deposit-#{d.id}") |> has_element?()
    end)
  end
end
