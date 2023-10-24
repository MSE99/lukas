defmodule LukasWeb.Operator.CourseLessonsLiveTest do
  use LukasWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lukas.LearningFixtures

  alias Lukas.Learning

  setup :register_and_log_in_user

  setup do
    %{course: course_fixture()}
  end

  describe "index" do
    test "should redirect if the id is not valid.", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/controls/courses/invalid/lessons")
      assert_redirect(lv, ~p"/controls/courses")
    end

    test "should redirect if the course does not exist", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/controls/courses/300/lessons")
      assert_redirect(lv, ~p"/controls/courses")
    end

    test "should render the course name and lessons.", %{conn: conn, course: course} do
      l1 = lesson_fixture(course)
      l2 = lesson_fixture(course)
      l3 = lesson_fixture(course)

      {:ok, lv, _html} = live(conn, ~p"/controls/courses/#{course.id}/lessons")

      html = render_async(lv)

      assert html =~ course.name
      assert html =~ l1.title
      assert html =~ l2.title
      assert html =~ l3.title
    end

    test "should react to lessons being added.", %{conn: conn, course: course} do
      {:ok, lv, _html} = live(conn, ~p"/controls/courses/#{course.id}/lessons")

      l1 = lesson_fixture(course)
      l2 = lesson_fixture(course)
      l3 = lesson_fixture(course)

      html = render_async(lv)

      assert html =~ course.name
      assert html =~ l1.title
      assert html =~ l2.title
      assert html =~ l3.title
    end

    test "should react to lessons being removed.", %{conn: conn, course: course} do
      {:ok, lv, _html} = live(conn, ~p"/controls/courses/#{course.id}/lessons")

      l1 = lesson_fixture(course)
      l2 = lesson_fixture(course)
      l3 = lesson_fixture(course)

      html = render_async(lv)

      assert html =~ course.name
      assert html =~ l1.title
      assert html =~ l2.title
      assert html =~ l3.title

      {:ok, _} = Learning.Course.Content.remove_lesson(l1)

      post_html = render(lv)

      refute post_html =~ l1.title
      assert post_html =~ l2.title
      assert post_html =~ l3.title
    end

    test "should react to lessons being edited.", %{conn: conn, course: course} do
      {:ok, lv, _html} = live(conn, ~p"/controls/courses/#{course.id}/lessons")

      l1 = lesson_fixture(course)
      l2 = lesson_fixture(course)
      l3 = lesson_fixture(course)

      html = render_async(lv)

      assert html =~ course.name
      assert html =~ l1.title
      assert html =~ l2.title
      assert html =~ l3.title

      {:ok, next_l1} = Learning.Course.Content.update_lesson(l1, %{"title" => "New Title"})

      post_html = render(lv)

      refute post_html =~ l1.title

      assert post_html =~ next_l1.title
      assert post_html =~ l2.title
      assert post_html =~ l3.title
    end

    test "should react to course being updated.", %{conn: conn, course: course} do
      {:ok, lv, _html} = live(conn, ~p"/controls/courses/#{course.id}/lessons")

      assert render_async(lv) =~ course.name

      {:ok, updated} = Learning.update_course(course, %{"name" => "FOO IS GREAT"})

      post_update_html = render_async(lv)

      refute post_update_html =~ course.name
      assert post_update_html =~ updated.name
    end
  end
end
