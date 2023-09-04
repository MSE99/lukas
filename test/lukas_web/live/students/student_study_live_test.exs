defmodule LukasWeb.Students.StudyLiveTest do
  use LukasWeb.ConnCase

  import Lukas.LearningFixtures
  import Phoenix.LiveViewTest

  alias Lukas.Learning

  def setup_tests(ctx) do
    auth_ctx = register_and_log_in_student(ctx)

    course = course_fixture()

    {:ok, _} = Learning.enroll_student(course, auth_ctx.user)

    Map.merge(auth_ctx, %{course: course})
  end

  test "should require an authenticated student.", %{conn: conn} do
    assert {:error, {:redirect, _}} = live(conn, ~p"/home/courses/10/study")
  end

  describe "basic" do
    setup [:setup_tests]

    test "should render the first lesson description.", %{
      conn: conn,
      course: course
    } do
      lesson1 = lesson_fixture(course)
      lesson2 = lesson_fixture(course)
      lesson3 = lesson_fixture(course)

      Enum.each(1..15, fn _ -> text_topic_fixture(lesson1) end)
      Enum.each(1..15, fn _ -> text_topic_fixture(lesson2) end)
      Enum.each(1..15, fn _ -> text_topic_fixture(lesson3) end)

      {:ok, _, html} = live(conn, ~p"/home/courses/#{course.id}/study?lesson_id=#{lesson1.id}")

      assert html =~ lesson1.title
      assert html =~ lesson1.description
    end

    test "should react to student making progress.", %{
      conn: conn,
      course: course,
      user: student
    } do
      lesson1 = lesson_fixture(course)
      lesson2 = lesson_fixture(course)
      lesson3 = lesson_fixture(course)

      Enum.each(1..15, fn _ -> text_topic_fixture(lesson1) end)
      Enum.each(1..15, fn _ -> text_topic_fixture(lesson2) end)
      Enum.each(1..15, fn _ -> text_topic_fixture(lesson3) end)

      {_, lessons} = Learning.get_progress(student, course.id)
      wanted_topic = Learning.get_topic(lesson1.id, Enum.at(Enum.at(lessons, 0).topics, 0).id)

      {:ok, lv, _} = live(conn, ~p"/home/courses/#{course.id}/study?lesson_id=#{lesson1.id}")

      Learning.progress_through_lesson(student, lesson1)

      html = render(lv)

      assert html =~ wanted_topic.title
      assert html =~ wanted_topic.content

      assert_patched(
        lv,
        ~p"/home/courses/#{course.id}/study?lesson_id=#{lesson1.id}&topic_id=#{wanted_topic.id}"
      )
    end

    test "progressing through lessons.", %{
      conn: conn,
      course: course,
      user: student
    } do
      lesson1 = lesson_fixture(course)
      lesson2 = lesson_fixture(course)
      lesson3 = lesson_fixture(course)

      {:ok, lv, _} = live(conn, ~p"/home/courses/#{course.id}/study?lesson_id=#{lesson1.id}")

      Learning.progress_through_lesson(student, lesson1)
      Learning.progress_through_lesson(student, lesson2)

      assert render(lv) =~ lesson3.title
      assert render(lv) =~ lesson3.description

      assert_patched(
        lv,
        ~p"/home/courses/#{course.id}/study?lesson_id=#{lesson3.id}"
      )
    end

    test "clicking on next button should bump the progress to the next lesson from the previous one.",
         %{
           conn: conn,
           course: course
         } do
      lesson1 = lesson_fixture(course)
      _lesson2 = lesson_fixture(course)
      lesson3 = lesson_fixture(course)

      {:ok, lv, _} = live(conn, ~p"/home/courses/#{course.id}/study?lesson_id=#{lesson1.id}")

      lv |> element("button", "next") |> render_click()
      lv |> element("button", "next") |> render_click()

      assert render(lv) =~ lesson3.title
      assert render(lv) =~ lesson3.description

      assert_patched(
        lv,
        ~p"/home/courses/#{course.id}/study?lesson_id=#{lesson3.id}"
      )
    end

    test "clicking on next button should bump the progress to the next topic from the previous one.",
         %{
           conn: conn,
           course: course
         } do
      lesson1 = lesson_fixture(course)
      text_topic_fixture(lesson1)

      lesson2 = lesson_fixture(course)
      text_topic_fixture(lesson2)

      lesson3 = lesson_fixture(course)

      {:ok, lv, _} = live(conn, ~p"/home/courses/#{course.id}/study?lesson_id=#{lesson1.id}")

      # Progressing through lesson 1 & topic 1
      lv |> element("button", "next") |> render_click()
      lv |> element("button", "next") |> render_click()

      # Progressing through lesson 2 & topic 2
      lv |> element("button", "next") |> render_click()
      lv |> element("button", "next") |> render_click()

      assert render(lv) =~ lesson3.title
      assert render(lv) =~ lesson3.description

      assert_patched(
        lv,
        ~p"/home/courses/#{course.id}/study?lesson_id=#{lesson3.id}"
      )
    end

    test "clicking on next button should bump the progress to the end of the course.",
         %{
           conn: conn,
           course: course
         } do
      lesson1 = lesson_fixture(course)
      text_topic_fixture(lesson1)

      lesson2 = lesson_fixture(course)
      text_topic_fixture(lesson2)

      lesson3 = lesson_fixture(course)
      text_topic_fixture(lesson3)

      {:ok, lv, _} = live(conn, ~p"/home/courses/#{course.id}/study?lesson_id=#{lesson1.id}")

      # Progressing through lesson 1 & topic 1
      lv |> element("button", "next") |> render_click()
      lv |> element("button", "next") |> render_click()

      # Progressing through lesson 2 & topic 2
      lv |> element("button", "next") |> render_click()
      lv |> element("button", "next") |> render_click()

      # Progressing through lesson 3 & topic 3
      lv |> element("button", "next") |> render_click()
      lv |> element("button", "next") |> render_click()

      html = render(lv)

      assert_patched(
        lv,
        ~p"/home/courses/#{course.id}/study"
      )

      refute html =~ lesson1.description
      refute html =~ lesson2.description
      refute html =~ lesson3.description
    end
  end
end
