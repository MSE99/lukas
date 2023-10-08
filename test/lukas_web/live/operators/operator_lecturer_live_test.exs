defmodule LukasWeb.Operator.LecturersLiveTest do
  use LukasWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lukas.AccountsFixtures

  setup :register_and_log_in_user

  # test "should only render the first 50 lecturers created.", %{conn: conn} do
  #   first_fifty = Enum.map(1..50, fn _ -> lecturer_fixture() end)
  #   last_fifty = Enum.map(1..50, fn _ -> lecturer_fixture() end)

  #   {:ok, lv, _} = live(conn, ~p"/controls/lecturers")

  #   html = render_async(lv)

  #   Enum.each(first_fifty, fn l -> assert html =~ l.name end)
  #   Enum.each(last_fifty, fn l -> refute html =~ l.name end)
  # end

  test "should react to lecturers being added.", %{conn: conn} do
    {:ok, lv, _} = live(conn, ~p"/controls/lecturers")
    render_async(lv)

    lecturers = Enum.map(1..30, fn _ -> lecturer_fixture() end)

    html = render(lv)

    Enum.each(lecturers, fn l -> assert html =~ l.name end)
  end
end
