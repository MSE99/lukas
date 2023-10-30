defmodule LukasWeb.Operator.CourseSettingsLiveTest do
  use LukasWeb.ConnCase, async: true

  alias Lukas.Learning

  import Phoenix.LiveViewTest
  import Lukas.LearningFixtures

  setup :register_and_log_in_lecturer

  setup %{user: user} do
    course = course_fixture()

    tag1 = tag_fixture()
    tag2 = tag_fixture()
    tag3 = tag_fixture()

    {:ok, _} = Learning.tag_course(course.id, tag1.id)
    {:ok, _} = Learning.tag_course(course.id, tag2.id)
    {:ok, _} = Learning.tag_course(course.id, tag3.id)

    {:ok, _} = Learning.Course.Staff.add_lecturer_to_course(course, user)

    %{course: course}
  end

  test "should redirect if the user is not assigned to the course.", %{conn: conn} do
    {:ok, lv, _} = live(conn, ~p"/tutor/my-courses/#{course_fixture().id}/settings")
    assert_redirect(lv, ~p"/tutor/my-courses")
  end

  test "should immediately redirect if the course id is invalid.", %{conn: conn} do
    assert {:error, {:redirect, _}} = live(conn, ~p"/tutor/my-courses/invalid/settings")
  end

  test "should redirect if it fails to find a course with a matching id.", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/tutor/my-courses/300/settings")
    assert_redirect(lv, ~p"/tutor/my-courses")
  end

  test "should render the course name and tags.", %{conn: conn, course: course} do
    {:ok, lv, _html} = live(conn, ~p"/tutor/my-courses/#{course.id}/settings")
    assert render_async(lv) =~ course.name
  end

  test "form should render errors on change.", %{conn: conn, course: course} do
    {:ok, lv, _html} = live(conn, ~p"/tutor/my-courses/#{course.id}/settings")
    render_async(lv)

    lv
    |> form("form", %{"course" => %{"name" => "", "description" => "desc"}})
    |> render_change()

    assert render(lv) =~ "can&#39;t be blank"
  end

  test "form should render errors on submit.", %{conn: conn, course: course} do
    {:ok, lv, _html} = live(conn, ~p"/tutor/my-courses/#{course.id}/settings")
    render_async(lv)

    lv
    |> form("form", %{"course" => %{"name" => "", "description" => "desc"}})
    |> render_submit()

    assert render(lv) =~ "can&#39;t be blank"
  end

  test "should update the course.", %{conn: conn, course: course} do
    tag = tag_fixture()

    {:ok, lv, _html} = live(conn, ~p"/tutor/my-courses/#{course.id}/settings")
    render_async(lv)

    lv |> element("#tags-#{tag.id}") |> render_click()

    lv
    |> form("form", %{"course" => %{"name" => "Next course name", "description" => "desc"}})
    |> render_submit()

    assert render(lv) =~ "Next course name"

    assert tag in Learning.list_course_tags(course)
  end
end
