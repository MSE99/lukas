defmodule LukasWeb.Students.CoursesLiveTest do
  use LukasWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lukas.LearningFixtures
  import Lukas.MoneyFixtures
  import Lukas.AccountsFixtures

  alias Lukas.Learning.Course.Students

  test "should require an authenticated student", %{conn: conn} do
    assert {:error, {:redirect, _}} = live(conn, ~p"/home/courses")
  end

  describe "index" do
    setup [:register_and_log_in_student]

    test "should render all enrolled courses.", %{conn: conn, user: user} do
      course1 = course_fixture()
      course2 = course_fixture()
      course3 = course_fixture()

      direct_deposit_fixture(user_fixture(), user, course1.price + course2.price + course3.price)

      {:ok, _} = Students.enroll_student(course1, user)
      {:ok, _} = Students.enroll_student(course2, user)
      {:ok, _} = Students.enroll_student(course3, user)

      {:ok, lv, _} = live(conn, ~p"/home/courses")

      html = render_async(lv)
      assert html =~ course1.name
      assert html =~ course2.name
      assert html =~ course3.name
    end

    test "should react to additional enrollments being created.", %{conn: conn, user: user} do
      course1 = course_fixture()
      course2 = course_fixture()
      course3 = course_fixture()

      direct_deposit_fixture(user_fixture(), user, course1.price + course2.price + course3.price)

      {:ok, lv, _} = live(conn, ~p"/home/courses")

      {:ok, _} = Students.enroll_student(course1, user)
      {:ok, _} = Students.enroll_student(course2, user)
      {:ok, _} = Students.enroll_student(course3, user)

      html = render_async(lv)

      assert html =~ course1.name
      assert html =~ course2.name
      assert html =~ course3.name
    end
  end
end
