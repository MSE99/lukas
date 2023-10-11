defmodule LukasWeb.Operators.StudentLive do
  use LukasWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lukas.AccountsFixtures
  import Lukas.MoneyFixtures
  import Lukas.LearningFixtures

  alias Lukas.Accounts

  setup :register_and_log_in_user

  setup do
    %{student: student_fixture()}
  end

  test "should redirect if the user id is invalid.", %{conn: conn} do
    assert {:error, {:redirect, _}} = live(conn, ~p"/controls/students/INVALID")
  end

  test "should redirect if the student does not exist.", %{conn: conn} do
    assert {:error, {:redirect, _}} = live(conn, ~p"/controls/students/4050123")
  end

  test "should render the student data.", %{conn: conn, student: student} do
    course = course_fixture()

    direct_deposit_fixture(user_fixture(), student, course.price)
    Lukas.Learning.Course.Students.enroll_student(course, student)

    {:ok, lv, _html} = live(conn, ~p"/controls/students/#{student.id}")

    html = render_async(lv)

    assert html =~ student.name
    assert html =~ course.name
  end

  test "should render a button for disabling/enabling students.", %{conn: conn, student: student} do
    course = course_fixture()

    {:ok, lv, _html} = live(conn, ~p"/controls/students/#{student.id}")
    render_async(lv)

    lv |> element("button#disable-button") |> render_click()
    refute Accounts.get_student(student.id).enabled

    lv |> element("button#enable-button") |> render_click()
    assert Accounts.get_student(student.id).enabled

    assert lv |> element("button#disable-button") |> has_element?()
  end

  test "should react to student updates.", %{conn: conn, student: student} do
    course = course_fixture()

    {:ok, lv, _html} = live(conn, ~p"/controls/students/#{student.id}")
    render_async(lv)

    {:ok, _} = Accounts.disable_user(student)

    assert lv |> element("button#enable-button") |> has_element?()
  end
end
