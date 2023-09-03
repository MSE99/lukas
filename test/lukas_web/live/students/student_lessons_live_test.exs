defmodule LukasWeb.Students.StudentLessonsLiveTest do
  use LukasWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lukas.LearningFixtures

  alias Lukas.Learning

  test "should require an authenticated operator.", %{conn: conn} do
    assert {:error, {:redirect, _}} = live(conn, ~p"/home/courses/10/lessons")
  end

  def setup_tests(ctx) do
    auth_ctx = register_and_log_in_student(ctx)

    course = course_fixture()

    Learning.enroll_student(course, auth_ctx.user)

    lessons = [
      lesson_fixture(course),
      lesson_fixture(course),
      lesson_fixture(course),
      lesson_fixture(course)
    ]

    Enum.each(lessons, fn lesson -> text_topic_fixture(lesson) end)

    Map.merge(auth_ctx, %{course: course, lessons: lessons})
  end

  describe "basics" do
    setup [:setup_tests]

    test "should render the course name and lessons with topics", %{
      conn: conn,
      course: course,
      lessons: lessons
    } do
      {:ok, _lv, html} = live(conn, ~p"/home/courses/#{course.id}/lessons")

      assert html =~ course.name

      Enum.each(lessons, fn lesson ->
        assert html =~ lesson.title
        {_, topics} = Learning.get_lesson_and_topic_names(course.id, lesson.id)
        Enum.each(topics, fn topic -> assert html =~ "#{topic.title} | unfinished" end)
      end)
    end

    test "should render the lesson title in a heading when visiting the lesson page", %{
      conn: conn,
      course: course,
      lessons: [lesson | _]
    } do
      {:ok, lv, _} = live(conn, ~p"/home/courses/#{course.id}/lessons/#{lesson.id}")
      assert lv |> element("h1", lesson.title) |> has_element?()
    end

    test "should render the text topic content when visiting the page", %{
      conn: conn,
      course: course,
      lessons: [lesson | _]
    } do
      text_topic = text_topic_fixture(lesson)

      {:ok, lv, _} =
        live(conn, ~p"/home/courses/#{course.id}/lessons/#{lesson.id}/topics/#{text_topic}")

      assert lv |> element("h1", text_topic.title) |> has_element?()
      assert lv |> element("p", text_topic.content) |> has_element?()
    end
  end
end
