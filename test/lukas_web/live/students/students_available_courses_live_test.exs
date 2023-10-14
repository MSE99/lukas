defmodule LukasWeb.Students.AvailableCoursesLiveTest do
  use LukasWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lukas.LearningFixtures
  import Lukas.AccountsFixtures

  alias Lukas.Learning.Course.Students

  test "should require an authenticated student", %{conn: conn} do
    assert {:error, {:redirect, _}} = live(conn, ~p"/home/courses/available")
  end

  describe "index" do
    setup [:register_and_log_in_student]

    test "should render all courses open to student.", %{conn: conn} do
      course1 = course_fixture()
      course2 = course_fixture()
      course3 = course_fixture()

      {:ok, lv, _} = live(conn, ~p"/home/courses/available")

      html = render_async(lv)

      assert html =~ course1.name
      assert html =~ course2.name
      assert html =~ course3.name
    end

    test "should react to new courses being added.", %{conn: conn} do
      {:ok, lv, _} = live(conn, ~p"/home/courses/available")

      course1 = course_fixture()
      course2 = course_fixture()
      course3 = course_fixture()

      html = render_async(lv)

      assert html =~ course1.name
      assert html =~ course2.name
      assert html =~ course3.name
    end

    test "should react to additional enrollments being created.", %{conn: conn, user: user} do
      course1 = course_fixture()
      course2 = course_fixture()
      course3 = course_fixture()

      {:ok, lv, _} = live(conn, ~p"/home/courses/available")

      Lukas.MoneyFixtures.direct_deposit_fixture(user_fixture(), user, 50_000.0)

      {:ok, _} = Students.enroll_student(course1, user)
      {:ok, _} = Students.enroll_student(course2, user)

      html = render_async(lv)

      refute html =~ course1.name
      refute html =~ course2.name
      assert html =~ course3.name
    end
  end
end
