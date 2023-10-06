defmodule LukasWeb.Operator.StudentsLiveTest do
  use LukasWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lukas.AccountsFixtures

  setup :register_and_log_in_user

  test "should render all students in the system.", %{conn: conn} do
    students = 1..150 |> Enum.map(fn _ -> student_fixture() end)

    {:ok, lv, _html} = live(conn, ~p"/controls/students")

    html = render_async(lv)

    Enum.each(students, fn s -> assert html =~ s.name end)
  end

  test "should react to students being added to the system.", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/controls/students")

    students = 1..150 |> Enum.map(fn _ -> student_fixture() end)

    html = render_async(lv)

    Enum.each(students, fn s -> assert html =~ s.name end)
  end
end
