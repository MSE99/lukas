defmodule LukasWeb.Lecturer.CourseLiveTest do
  use LukasWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lukas.LearningFixtures
  import Lukas.AccountsFixtures
  import Lukas.MoneyFixtures

  alias Lukas.Learning.Course.{Content, Students}

  def create_course(ctx) do
    %{user: user} = ctx
    course = course_fixture()

    {:ok, _} = Lukas.Learning.Course.Staff.add_lecturer_to_course(course, user)

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
    assert {:error, {:redirect, _}} = live(conn, ~p"/tutor/my-courses/15")
  end

  describe "show" do
    setup [:register_and_log_in_lecturer, :create_course]

    test "should redirect if the course id is invalid.", %{conn: conn} do
      assert {:error, {:redirect, _}} = live(conn, ~p"/tutor/my-courses/invalid")
    end

    test "should redirect if the course id is valid but no matching course is found.",
         %{
           conn: conn
         } do
      assert {:error, {:redirect, _}} = live(conn, ~p"/tutor/my-courses/10")
    end

    test "should render the course data if the course id is valid.", %{
      conn: conn,
      course: course,
      lesson: lesson
    } do
      {:ok, _, html} = live(conn, ~p"/tutor/my-courses/#{course.id}")

      assert html =~ course.name
      assert html =~ "#{course.price |> :erlang.float_to_binary(decimals: 1)} LYD"
      assert html =~ lesson.title
    end

    test "should handle students enrollments.", %{conn: conn, course: course} do
      {:ok, lv, _} = live(conn, ~p"/tutor/my-courses/#{course.id}")

      student = student_fixture()
      direct_deposit_fixture(user_fixture(), student, course.price)

      {:ok, _} = Students.enroll_student(course, student)

      assert render(lv) =~ course.name
    end
  end

  describe "new lesson" do
    setup [:register_and_log_in_lecturer, :create_course]

    test "form should render errors on change.", %{conn: conn, course: course} do
      {:ok, lv, _} = live(conn, ~p"/tutor/my-courses/#{course.id}/new-lesson")

      render_result =
        lv
        |> form("form", %{
          "lesson" => %{"title" => "", "description" => "foo is great bar is none"}
        })
        |> render_change()

      assert render_result =~ "can&#39;t be blank"
    end

    test "form should render errors on submit.", %{conn: conn, course: course} do
      {:ok, lv, _} = live(conn, ~p"/tutor/my-courses/#{course.id}/new-lesson")

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
      {:ok, lv, _} = live(conn, ~p"/tutor/my-courses/#{course.id}/new-lesson")

      lv
      |> form("form", %{
        "lesson" => %{
          "title" => "Listener",
          "description" => "foo is great bar is none"
        }
      })
      |> render_submit()

      assert_patched(lv, ~p"/tutor/my-courses/#{course.id}")
      assert render(lv) =~ "Listener"
    end
  end

  describe "edit lesson" do
    setup [:register_and_log_in_lecturer, :create_course]

    test "form should render errors on change.", %{
      conn: conn,
      course: course,
      lesson: lesson
    } do
      {:ok, lv, _} =
        live(conn, ~p"/tutor/my-courses/#{course.id}/lessons/#{lesson.id}/edit-lesson")

      render_result =
        lv
        |> form("form", %{
          "lesson" => %{"title" => "", "description" => "foo is great bar is none"}
        })
        |> render_change()

      assert render_result =~ "can&#39;t be blank"
    end

    test "form should render errors on submit.", %{
      conn: conn,
      course: course,
      lesson: lesson
    } do
      {:ok, lv, _} =
        live(conn, ~p"/tutor/my-courses/#{course.id}/lessons/#{lesson.id}/edit-lesson")

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
        live(conn, ~p"/tutor/my-courses/#{course.id}/lessons/#{lesson.id}/edit-lesson")

      lv
      |> form("form", %{
        "lesson" => %{
          "title" => "Bar Baz Naz",
          "description" => "foo is great bar is none"
        }
      })
      |> render_submit()

      assert_patched(lv, ~p"/tutor/my-courses/#{course.id}")
      assert render(lv) =~ "Bar Baz Naz"
    end
  end

  describe "lecturers" do
    setup [:register_and_log_in_lecturer, :create_course]

    test "should render all lecturers assigned to the course.", %{
      conn: conn,
      course: course
    } do
      lect1 = lecturer_fixture()
      lect2 = lecturer_fixture()

      teaching_fixture(course, lect1)
      teaching_fixture(course, lect2)

      {:ok, _lv, html} = live(conn, ~p"/tutor/my-courses/#{course.id}")

      assert html =~ lect1.name
      assert html =~ lect2.name
    end

    test "should react to lecturers being assigned to the course.", %{
      conn: conn,
      course: course
    } do
      {:ok, lv, _} = live(conn, ~p"/tutor/my-courses/#{course.id}")

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
      {:ok, lv, _} = live(conn, ~p"/tutor/my-courses/#{course.id}")

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

  describe "lesson deletion" do
    setup [:register_and_log_in_lecturer, :create_course]

    test "clicking on delete should delete a lesson.", %{conn: conn, course: course} do
      {:ok, lv, _} = live(conn, ~p"/tutor/my-courses/#{course.id}")

      lesson = lesson_fixture(course)

      lv
      |> element("#lesson-delete-#{lesson.id}")
      |> render_click()

      refute render(lv) =~ lesson.title
    end

    test "should react to lessons being removed.", %{conn: conn, course: course} do
      {:ok, lv, _} = live(conn, ~p"/tutor/my-courses/#{course.id}")

      lesson = lesson_fixture(course)
      assert render(lv) =~ lesson.title

      Content.remove_lesson(lesson)

      refute render(lv) =~ lesson.title
    end
  end
end
