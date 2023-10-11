defmodule LukasWeb.Operators.StudentLive do
  use LukasWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lukas.AccountsFixtures
  import Lukas.MoneyFixtures
  import Lukas.LearningFixtures

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
end
