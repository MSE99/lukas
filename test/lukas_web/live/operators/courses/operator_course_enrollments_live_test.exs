defmodule LukasWeb.Operator.CourseEnrollmentsLiveTest do
  use LukasWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lukas.LearningFixtures
  import Lukas.AccountsFixtures
  import Lukas.MoneyFixtures

  alias Lukas.Learning
  alias Lukas.Learning.Course.Students

  setup do
    course = course_fixture()
    %{course: course}
  end

  test "should require an authenticated operator.", %{conn: conn, course: course} do
    assert {:error, {:redirect, _}} = live(conn, ~p"/controls/courses/#{course.id}/enrollments")
  end

  describe "index" do
    setup [:register_and_log_in_user]

    test "should redirect if the course id is invalid.", %{conn: conn} do
      assert {:error, {:redirect, _}} =
               live(conn, ~p"/controls/courses/foo-is-great-bar-is-none/enrollments")
    end

    test "should redirect if the course id is valid but matches no course.", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/controls/courses/10/enrollments")
      assert_redirected(lv, ~p"/controls/courses")
    end

    test "should render all enrolled students.", %{conn: conn, course: course} do
      student1 = student_fixture()
      direct_deposit_fixture(user_fixture(), student1, course.price)

      student2 = student_fixture()
      direct_deposit_fixture(user_fixture(), student2, course.price)

      student3 = student_fixture()
      direct_deposit_fixture(user_fixture(), student3, course.price)

      {:ok, _} = Students.enroll_student(course, student1)
      {:ok, _} = Students.enroll_student(course, student2)
      {:ok, _} = Students.enroll_student(course, student3)

      {:ok, lv, _} = live(conn, ~p"/controls/courses/#{course.id}/enrollments")

      html = render_async(lv)

      assert html =~ "#{student1.name}"
      assert html =~ "#{student2.name}"
      assert html =~ "#{student3.name}"
    end

    test "should react to enrolled students being added.", %{conn: conn, course: course} do
      {:ok, lv, _} = live(conn, ~p"/controls/courses/#{course.id}/enrollments")

      student1 = student_fixture()
      direct_deposit_fixture(user_fixture(), student1, course.price)

      student2 = student_fixture()
      direct_deposit_fixture(user_fixture(), student2, course.price)

      student3 = student_fixture()
      direct_deposit_fixture(user_fixture(), student3, course.price)

      {:ok, _} = Students.enroll_student(course, student1)
      {:ok, _} = Students.enroll_student(course, student2)
      {:ok, _} = Students.enroll_student(course, student3)

      html = render_async(lv)

      assert html =~ "#{student1.name}"
      assert html =~ "#{student2.name}"
      assert html =~ "#{student3.name}"
    end

    test "should ignore non enrollment related course events.", %{conn: conn, course: course} do
      {:ok, lv, _} = live(conn, ~p"/controls/courses/#{course.id}/enrollments")

      student1 = student_fixture()
      direct_deposit_fixture(user_fixture(), student1, course.price)

      student2 = student_fixture()
      direct_deposit_fixture(user_fixture(), student2, course.price)

      student3 = student_fixture()
      direct_deposit_fixture(user_fixture(), student3, course.price)

      {:ok, _} = Students.enroll_student(course, student1)
      {:ok, _} = Students.enroll_student(course, student2)
      {:ok, _} = Students.enroll_student(course, student3)

      {:ok, _} = Learning.update_course(course, %{"name" => "cool course"})

      html = render_async(lv)
      assert html =~ "#{student1.name}"
      assert html =~ "#{student2.name}"
      assert html =~ "#{student3.name}"
    end
  end
end
