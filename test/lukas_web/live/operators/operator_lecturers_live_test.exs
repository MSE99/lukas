defmodule LukasWeb.Operator.LecturersLiveTest do
  use LukasWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lukas.AccountsFixtures

  alias Lukas.Accounts

  setup :register_and_log_in_user

  test "should render the first 50 lecturers.", %{conn: conn} do
    lecturers = Enum.map(1..30, fn _ -> lecturer_fixture() end)

    {:ok, lv, _} = live(conn, ~p"/controls/lecturers")
    html = render_async(lv)

    Enum.each(lecturers, fn l -> assert html =~ l.name end)
  end

  test "should react to lecturers being added when on first page.", %{conn: conn} do
    {:ok, lv, _} = live(conn, ~p"/controls/lecturers")
    render_async(lv)

    lecturers = Enum.map(1..30, fn _ -> lecturer_fixture() end)
    html = render_async(lv)

    Enum.each(lecturers, fn l -> assert html =~ l.name end)
  end

  test "should render a button for disabling the lecturers.", %{conn: conn} do
    lect = lecturer_fixture()

    {:ok, lv, _} = live(conn, ~p"/controls/lecturers")

    render_async(lv)

    lv
    |> element("button#lecturer-#{lect.id}-disable")
    |> render_click()

    assert Accounts.get_lecturer!(lect.id).enabled == false
  end

  test "should render a button for enabling the lecturers.", %{conn: conn} do
    lect = lecturer_fixture()

    {:ok, lv, _} = live(conn, ~p"/controls/lecturers")

    render_async(lv)

    lv |> element("button#lecturer-#{lect.id}-disable") |> render_click()
    lv |> element("button#lecturer-#{lect.id}-enable") |> render_click()

    assert Accounts.get_lecturer!(lect.id).enabled
  end
end
