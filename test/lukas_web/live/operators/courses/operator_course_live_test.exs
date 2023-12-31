defmodule LukasWeb.Courses.CourseLiveTest do
  use LukasWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lukas.LearningFixtures
  import Lukas.AccountsFixtures
  import Lukas.MoneyFixtures

  alias Lukas.Learning
  alias Lukas.Learning.Course.Students

  def create_course(ctx), do: Map.put(ctx, :course, course_fixture())

  test "should require an authenticated admin.", %{conn: conn} do
    assert {:error, {:redirect, _}} = live(conn, ~p"/controls/courses/15")
  end

  describe "show" do
    setup [:register_and_log_in_user, :create_course]

    test "should redirect if the course id is invalid.", %{conn: conn} do
      assert {:error, {:redirect, _}} = live(conn, ~p"/controls/courses/invalid")
    end

    test "should redirect if the course id is valid but no matching course is found.",
         %{
           conn: conn
         } do
      assert {:error, {:redirect, _}} = live(conn, ~p"/controls/courses/10")
    end

    test "should render the course data if the course id is valid.", %{
      conn: conn,
      course: course
    } do
      {:ok, _, html} = live(conn, ~p"/controls/courses/#{course.id}")

      assert html =~ course.name
      assert html =~ "#{course.price |> :erlang.float_to_binary(decimals: 1)} LYD"
      assert html =~ course.description
    end

    test "should handle students enrollments.", %{conn: conn, course: course} do
      {:ok, lv, _} = live(conn, ~p"/controls/courses/#{course.id}")

      student = student_fixture()
      direct_deposit_fixture(user_fixture(), student, 50_000.0)
      {:ok, _} = Students.enroll_student(course, student)

      assert render(lv) =~ course.name
    end

    test "should render all course tags.", %{conn: conn, course: course} do
      tag1 = tag_fixture()
      tag2 = tag_fixture()
      tag3 = tag_fixture()

      {:ok, _} = Learning.tag_course(course.id, tag1.id)
      {:ok, _} = Learning.tag_course(course.id, tag2.id)
      {:ok, _} = Learning.tag_course(course.id, tag3.id)

      {:ok, lv, _} = live(conn, ~p"/controls/courses/#{course.id}")

      html = render(lv)

      assert html =~ tag1.name
      assert html =~ tag2.name
      assert html =~ tag3.name
    end

    test "should render 0.0 if the course has no price.", %{conn: conn, course: course} do
      student1 = student_fixture()
      student2 = student_fixture()

      direct_deposit_fixture(user_fixture(), student1, 50_000.0)
      direct_deposit_fixture(user_fixture(), student2, 50_000.0)

      {:ok, _} = Students.enroll_student(course, student1)
      {:ok, _} = Students.enroll_student(course, student2)

      {:ok, _, html} = live(conn, ~p"/controls/courses/#{course.id}")

      assert html =~ "#{:erlang.float_to_binary(course.price * 2, decimals: 2)} LYD"
    end

    test "should react to course being purchased.", %{conn: conn, course: course} do
      {:ok, lv, _} = live(conn, ~p"/controls/courses/#{course.id}")

      student1 = student_fixture()
      student2 = student_fixture()

      direct_deposit_fixture(user_fixture(), student1, 50_000.0)
      direct_deposit_fixture(user_fixture(), student2, 50_000.0)

      {:ok, _} = Students.enroll_student(course, student1)
      {:ok, _} = Students.enroll_student(course, student2)

      assert render(lv) =~ "#{:erlang.float_to_binary(course.price * 2, decimals: 2)} LYD"
    end
  end

  describe "lecturers" do
    setup [:register_and_log_in_user, :create_course]

    test "should render all lecturers assigned to the course.", %{
      conn: conn,
      course: course
    } do
      lect1 = lecturer_fixture()
      lect2 = lecturer_fixture()

      teaching_fixture(course, lect1)
      teaching_fixture(course, lect2)

      {:ok, _lv, html} = live(conn, ~p"/controls/courses/#{course.id}")

      assert html =~ lect1.name
      assert html =~ lect2.name
    end

    test "should react to lecturers being assigned to the course.", %{
      conn: conn,
      course: course
    } do
      {:ok, lv, _} = live(conn, ~p"/controls/courses/#{course.id}")

      lect1 = lecturer_fixture()
      lect2 = lecturer_fixture()

      teaching_fixture(course, lect1)
      teaching_fixture(course, lect2)

      html = render(lv)

      assert html =~ lect1.name
      assert html =~ lect2.name
    end

    test "should react to lecturers being removed from the course.", %{
      conn: conn,
      course: course
    } do
      {:ok, lv, _} = live(conn, ~p"/controls/courses/#{course.id}")

      lect1 = lecturer_fixture()
      lect2 = lecturer_fixture()

      teaching_fixture(course, lect1)
      teaching_fixture(course, lect2)

      Lukas.Learning.Course.Staff.remove_lecturer_from_course(course, lect1)

      html = render(lv)

      refute html =~ lect1.name
      assert html =~ lect2.name
    end
  end
end
