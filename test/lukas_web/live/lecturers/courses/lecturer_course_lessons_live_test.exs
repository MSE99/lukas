defmodule LukasWeb.Lecturer.CourseLessonsLiveTest do
  use LukasWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Lukas.LearningFixtures

  alias Lukas.Learning

  setup :register_and_log_in_lecturer

  setup %{user: user} do
    course = course_fixture()
    {:ok, _} = Learning.Course.Staff.add_lecturer_to_course(course, user)
    %{course: course}
  end

  describe "index" do
    test "should redirect if the id is not valid.", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/tutor/my-courses/invalid/lessons")
      assert_redirect(lv, ~p"/tutor/my-courses")
    end

    test "should redirect if the course does not exist", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/tutor/my-courses/300/lessons")
      assert_redirect(lv, ~p"/tutor/my-courses")
    end

    test "should redirect if the user has no access to the course.", %{conn: conn} do
      course = course_fixture()
      {:ok, lv, _html} = live(conn, ~p"/tutor/my-courses/#{course.id}/lessons")
      assert_redirect(lv, ~p"/tutor/my-courses")
    end

    test "should render the course name and lessons.", %{conn: conn, course: course} do
      l1 = lesson_fixture(course)
      l2 = lesson_fixture(course)
      l3 = lesson_fixture(course)

      {:ok, lv, _html} = live(conn, ~p"/tutor/my-courses/#{course.id}/lessons")

      html = render_async(lv)

      assert html =~ course.name
      assert html =~ l1.title
      assert html =~ l2.title
      assert html =~ l3.title
    end

    test "should react to lessons being added.", %{conn: conn, course: course} do
      {:ok, lv, _html} = live(conn, ~p"/tutor/my-courses/#{course.id}/lessons")

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
      {:ok, lv, _html} = live(conn, ~p"/tutor/my-courses/#{course.id}/lessons")

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
      {:ok, lv, _html} = live(conn, ~p"/tutor/my-courses/#{course.id}/lessons")

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
      {:ok, lv, _html} = live(conn, ~p"/tutor/my-courses/#{course.id}/lessons")

      assert render_async(lv) =~ course.name

      {:ok, updated} = Learning.update_course(course, %{"name" => "FOO IS GREAT"})

      post_update_html = render_async(lv)

      refute post_update_html =~ course.name
      assert post_update_html =~ updated.name
    end
  end

  describe "new" do
    test "should render errors on change.", %{conn: conn, course: course} do
      {:ok, lv, _} = live(conn, ~p"/tutor/my-courses/#{course.id}/lessons")

      render_async(lv)

      lv |> element("#new-button") |> render_click()

      lv
      |> form("form", %{"lesson" => %{"title" => "", "description" => "foo is great bar is none"}})
      |> render_change()

      assert render(lv) =~ "can&#39;t be blank"
    end

    test "should render errors on submit.", %{conn: conn, course: course} do
      {:ok, lv, _} = live(conn, ~p"/tutor/my-courses/#{course.id}/lessons")

      render_async(lv)

      lv |> element("#new-button") |> render_click()

      lv
      |> form("form", %{"lesson" => %{"title" => "", "description" => "foo is great bar is none"}})
      |> render_submit()

      assert render(lv) =~ "can&#39;t be blank"
    end

    test "should create and render the new lesson on screen.", %{conn: conn, course: course} do
      {:ok, lv, _} = live(conn, ~p"/tutor/my-courses/#{course.id}/lessons")

      render_async(lv)

      lv |> element("#new-button") |> render_click()

      lv
      |> form("form", %{
        "lesson" => %{"title" => "Cool title", "description" => "foo is great bar is none"}
      })
      |> render_submit()

      assert render(lv) =~ "Cool title"
    end
  end

  describe "edit" do
    test "should render errors on change.", %{conn: conn, course: course} do
      l1 = lesson_fixture(course)

      {:ok, lv, _} = live(conn, ~p"/tutor/my-courses/#{course.id}/lessons")

      render_async(lv)

      lv |> element("#lessons-#{l1.id}-edit") |> render_click()

      lv
      |> form("form", %{"lesson" => %{"title" => "", "description" => "foo is great bar is none"}})
      |> render_change()

      assert render(lv) =~ "can&#39;t be blank"
    end

    test "should render errors on submit.", %{conn: conn, course: course} do
      l1 = lesson_fixture(course)

      {:ok, lv, _} = live(conn, ~p"/tutor/my-courses/#{course.id}/lessons")

      render_async(lv)

      lv |> element("#lessons-#{l1.id}-edit") |> render_click()

      lv
      |> form("form", %{"lesson" => %{"title" => "", "description" => "foo is great bar is none"}})
      |> render_submit()

      assert render(lv) =~ "can&#39;t be blank"
    end

    test "should edit the lesson.", %{conn: conn, course: course} do
      l1 = lesson_fixture(course)
      l2 = lesson_fixture(course)

      {:ok, lv, _} = live(conn, ~p"/tutor/my-courses/#{course.id}/lessons")

      render_async(lv)

      lv |> element("#lessons-#{l1.id}-edit") |> render_click()

      lv
      |> form("form", %{
        "lesson" => %{
          "title" => "Next title for edit",
          "description" => "foo is great bar is none"
        }
      })
      |> render_submit()

      html = render(lv)

      assert html =~ "Next title for edit"
      assert html =~ l2.title

      refute html =~ l1.title
    end
  end

  describe "delete" do
    test "should render a button for deleting the course lesson.", %{conn: conn, course: course} do
      l1 = lesson_fixture(course)
      l2 = lesson_fixture(course)
      l3 = lesson_fixture(course)

      {:ok, lv, _html} = live(conn, ~p"/tutor/my-courses/#{course.id}/lessons")
      render_async(lv)

      lv |> element("#lessons-#{l1.id}-delete") |> render_click()

      html = render(lv)

      assert html =~ l2.title
      assert html =~ l3.title
      refute html =~ l1.title
    end
  end
end
