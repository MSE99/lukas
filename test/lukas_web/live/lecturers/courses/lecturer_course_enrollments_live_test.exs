defmodule LukasWeb.Lecturers.CourseEnrollmentsLiveTest do
  use LukasWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lukas.LearningFixtures
  import Lukas.AccountsFixtures

  alias Lukas.Learning
  alias Lukas.Learning.Course.Students

  setup do
    course = course_fixture()
    %{course: course}
  end

  test "should require an authenticated operator.", %{conn: conn, course: course} do
    assert {:error, {:redirect, _}} = live(conn, ~p"/tutor/my-courses/#{course.id}/enrollments")
  end

  describe "index" do
    setup [:register_and_log_in_lecturer]

    test "should redirect if the course id is invalid.", %{conn: conn} do
      assert {:error, {:redirect, _}} =
               live(conn, ~p"/tutor/my-courses/foo-is-great-bar-is-none/enrollments")
    end

    test "should redirect if the course id is valid but matches no course.", %{conn: conn} do
      assert {:error, {:redirect, _}} = live(conn, ~p"/tutor/my-courses/10/enrollments")
    end

    test "should render all enrolled students.", %{conn: conn, course: course} do
      student1 = user_fixture(%{kind: :student})
      student2 = user_fixture(%{kind: :student})
      student3 = user_fixture(%{kind: :student})

      {:ok, _} = Students.enroll_student(course, student1)
      {:ok, _} = Students.enroll_student(course, student2)
      {:ok, _} = Students.enroll_student(course, student3)

      {:ok, _lv, html} = live(conn, ~p"/tutor/my-courses/#{course.id}/enrollments")

      assert html =~ "#{student1.name}"
      assert html =~ "#{student2.name}"
      assert html =~ "#{student3.name}"
    end

    test "should react to enrolled students being added.", %{conn: conn, course: course} do
      {:ok, lv, _} = live(conn, ~p"/tutor/my-courses/#{course.id}/enrollments")

      student1 = user_fixture(%{kind: :student})
      student2 = user_fixture(%{kind: :student})
      student3 = user_fixture(%{kind: :student})

      {:ok, _} = Students.enroll_student(course, student1)
      {:ok, _} = Students.enroll_student(course, student2)
      {:ok, _} = Students.enroll_student(course, student3)

      html = render(lv)
      assert html =~ "#{student1.name}"
      assert html =~ "#{student2.name}"
      assert html =~ "#{student3.name}"
    end

    test "should ignore non enrollment related course events.", %{conn: conn, course: course} do
      {:ok, lv, _} = live(conn, ~p"/tutor/my-courses/#{course.id}/enrollments")

      student1 = user_fixture(%{kind: :student})
      student2 = user_fixture(%{kind: :student})
      student3 = user_fixture(%{kind: :student})

      {:ok, _} = Students.enroll_student(course, student1)
      {:ok, _} = Students.enroll_student(course, student2)
      {:ok, _} = Students.enroll_student(course, student3)

      {:ok, _} = Learning.update_course(course, %{"name" => "cool course"})

      html = render(lv)
      assert html =~ "#{student1.name}"
      assert html =~ "#{student2.name}"
      assert html =~ "#{student3.name}"
    end
  end
end
