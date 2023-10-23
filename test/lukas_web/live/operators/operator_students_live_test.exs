defmodule LukasWeb.Operator.StudentsLiveTest do
  use LukasWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lukas.AccountsFixtures

  setup :register_and_log_in_user

  test "should render all students in the system.", %{conn: conn} do
    students = 1..10 |> Enum.map(fn _ -> student_fixture() end)

    {:ok, lv, _html} = live(conn, ~p"/controls/students")

    html = render_async(lv)

    Enum.each(students, fn s -> assert html =~ s.name end)
  end

  test "should react to students being added to the system.", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/controls/students")

    students = 1..10 |> Enum.map(fn _ -> student_fixture() end)

    html = render_async(lv)

    Enum.each(students, fn s -> assert html =~ s.name end)
  end

  test "should render a disable button for disabling the student.", %{conn: conn} do
    student = student_fixture()

    {:ok, lv, _html} = live(conn, ~p"/controls/students")
    render_async(lv)

    lv |> element("button#student-#{student.id}-disable") |> render_click()
  end

  test "should render an enable button for enabling the student.", %{conn: conn} do
    student = student_fixture()

    {:ok, lv, _html} = live(conn, ~p"/controls/students")
    render_async(lv)

    lv |> element("button#student-#{student.id}-disable") |> render_click()
    lv |> element("button#student-#{student.id}-enable") |> render_click()
  end

  test "should render a search bar for getting a student by name.", %{conn: conn} do
    1..100 |> Enum.each(fn _ -> student_fixture() end)

    student = student_fixture()

    {:ok, lv, _html} = live(conn, ~p"/controls/students")

    lv |> form("form#search-form", %{"name" => student.name}) |> render_submit()

    assert render_async(lv, 500) =~ student.name
  end
end
