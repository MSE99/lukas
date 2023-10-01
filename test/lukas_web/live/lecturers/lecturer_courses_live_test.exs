defmodule LukasWeb.Lecturers.CoursesLiveTest do
  use LukasWeb.ConnCase

  import Lukas.LearningFixtures
  import Phoenix.LiveViewTest

  alias Lukas.Learning

  setup :register_and_log_in_lecturer

  test "should render all lecturers courses.", %{conn: conn, user: user} do
    c1 = course_fixture()
    c2 = course_fixture()

    {:ok, _} = Learning.Course.Staff.add_lecturer_to_course(c1, user)
    {:ok, _} = Learning.Course.Staff.add_lecturer_to_course(c2, user)

    not_given = course_fixture()

    {:ok, _, html} = live(conn, ~p"/tutor/my-courses")

    assert html =~ c1.name
    assert html =~ c2.name
    refute html =~ not_given.name
  end

  test "should react to user being added to course.", %{conn: conn, user: user} do
    {:ok, lv, _} = live(conn, ~p"/tutor/my-courses")

    c1 = course_fixture()
    c2 = course_fixture()

    {:ok, _} = Learning.Course.Staff.add_lecturer_to_course(c1, user)
    {:ok, _} = Learning.Course.Staff.add_lecturer_to_course(c2, user)

    not_given = course_fixture()

    html = render(lv)

    assert html =~ c1.name
    assert html =~ c2.name
    refute html =~ not_given.name
  end

  test "should react to user being removed from course.", %{conn: conn, user: user} do
    c1 = course_fixture()
    c2 = course_fixture()
    c3 = course_fixture()

    {:ok, _} = Learning.Course.Staff.add_lecturer_to_course(c1, user)
    {:ok, _} = Learning.Course.Staff.add_lecturer_to_course(c2, user)

    {:ok, lv, _} = live(conn, ~p"/tutor/my-courses")

    {:ok, _} = Learning.Course.Staff.remove_lecturer_from_course(c1, user)
    {:ok, _} = Learning.Course.Staff.remove_lecturer_from_course(c2, user)
    {:ok, _} = Learning.Course.Staff.add_lecturer_to_course(c3, user)

    html = render(lv)

    refute html =~ c1.name
    refute html =~ c2.name

    assert html =~ c3.name
  end
end
