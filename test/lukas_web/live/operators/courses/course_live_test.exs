defmodule LukasWeb.Courses.CourseLiveTest do
  use LukasWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lukas.LearningFixtures

  def create_course(ctx) do
    course = course_fixture()

    lesson =
      lesson_fixture(course, %{
        "title" => "Operations",
        "description" => "a lesson about operations"
      })

    ctx
    |> Map.put(:course, course)
    |> Map.put(:lesson, lesson)
  end

  test "should require an authenticated admin.", %{conn: conn} do
    assert {:error, {:redirect, _}} = live(conn, ~p"/controls/courses/15")
  end

  describe "show" do
    setup [:register_and_log_in_user, :create_course]

    test "should redirect if the course id is invalid.", %{conn: conn} do
      assert {:error, {:redirect, _}} = live(conn, ~p"/controls/courses/invalid")
    end

    test "should redirect if the course id is valid but no matching course is found.", %{
      conn: conn
    } do
      assert {:error, {:redirect, _}} = live(conn, ~p"/controls/courses/10")
    end

    test "should render the course data if the course id is valid.", %{
      conn: conn,
      course: course,
      lesson: lesson
    } do
      {:ok, _, html} = live(conn, ~p"/controls/courses/#{course.id}")

      assert html =~ course.name
      assert html =~ lesson.title
    end
  end

  describe "new lesson" do
    setup [:register_and_log_in_user, :create_course]

    test "form should render errors on change.", %{conn: conn, course: course} do
      {:ok, lv, _} = live(conn, ~p"/controls/courses/#{course.id}/new-lesson")

      render_result =
        lv
        |> form("form", %{
          "lesson" => %{"title" => "", "description" => "foo is great bar is none"}
        })
        |> render_change()

      assert render_result =~ "can&#39;t be blank"
    end

    test "form should render errors on submit.", %{conn: conn, course: course} do
      {:ok, lv, _} = live(conn, ~p"/controls/courses/#{course.id}/new-lesson")

      render_result =
        lv
        |> form("form", %{
          "lesson" => %{"title" => "", "description" => "foo is great bar is none"}
        })
        |> render_submit()

      assert render_result =~ "can&#39;t be blank"
    end

    test "should create a new lesson if all lesson props are valid.", %{
      conn: conn,
      course: course
    } do
      {:ok, lv, _} = live(conn, ~p"/controls/courses/#{course.id}/new-lesson")

      lv
      |> form("form", %{
        "lesson" => %{"title" => "Listener", "description" => "foo is great bar is none"}
      })
      |> render_submit()

      assert_patched(lv, ~p"/controls/courses/#{course.id}")
      assert render(lv) =~ "Listener"
    end
  end

  describe "edit lesson" do
    setup [:register_and_log_in_user, :create_course]

    test "form should render errors on change.", %{conn: conn, course: course, lesson: lesson} do
      {:ok, lv, _} =
        live(conn, ~p"/controls/courses/#{course.id}/lessons/#{lesson.id}/edit-lesson")

      render_result =
        lv
        |> form("form", %{
          "lesson" => %{"title" => "", "description" => "foo is great bar is none"}
        })
        |> render_change()

      assert render_result =~ "can&#39;t be blank"
    end

    test "form should render errors on submit.", %{conn: conn, course: course, lesson: lesson} do
      {:ok, lv, _} =
        live(conn, ~p"/controls/courses/#{course.id}/lessons/#{lesson.id}/edit-lesson")

      render_result =
        lv
        |> form("form", %{
          "lesson" => %{"title" => "", "description" => "foo is great bar is none"}
        })
        |> render_submit()

      assert render_result =~ "can&#39;t be blank"
    end

    test "should patch back the course page and update the lesson title", %{
      conn: conn,
      course: course,
      lesson: lesson
    } do
      {:ok, lv, _} =
        live(conn, ~p"/controls/courses/#{course.id}/lessons/#{lesson.id}/edit-lesson")

      lv
      |> form("form", %{
        "lesson" => %{"title" => "Bar Baz Naz", "description" => "foo is great bar is none"}
      })
      |> render_submit()

      assert_patched(lv, ~p"/controls/courses/#{course.id}")
      assert render(lv) =~ "Bar Baz Naz"
    end
  end
end
