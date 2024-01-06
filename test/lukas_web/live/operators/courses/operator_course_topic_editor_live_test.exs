defmodule LukasWeb.Operator.LessonEditorLiveTest do
  use LukasWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Lukas.LearningFixtures

  test "should require an authenticated operator.", %{conn: conn} do
    {:error, {:redirect, _}} = live(conn, ~p"/controls/courses/11/lessons/15/topics/new")
  end

  describe "new lesson" do
    setup :register_and_log_in_user

    setup do
      course = course_fixture()
      lesson = lesson_fixture(course)
      %{course: course, lesson: lesson}
    end

    test "should redirect if the course id is invalid.", %{conn: conn} do
      {:ok, lv, _} = live(conn, ~p"/controls/courses/invalid/lessons/10/topics/new")
      assert_redirect(lv, ~p"/controls/courses")
    end

    test "should redirect if the course cannot be found is invalid.", %{conn: conn} do
      {:ok, lv, _} = live(conn, ~p"/controls/courses/5000000000/lessons/10/topics/new")
      assert_redirect(lv, ~p"/controls/courses")
    end

    test "should redirect if the lesson id is invalid.", %{conn: conn, course: course} do
      {:ok, lv, _} = live(conn, ~p"/controls/courses/#{course.id}/lessons/INVALID/topics/new")
      assert_redirect(lv, ~p"/controls/courses")
    end

    test "should redirect if the lesson cannot be found.", %{conn: conn, course: course} do
      {:ok, lv, _} =
        live(conn, ~p"/controls/courses/#{course.id}/lessons/509999123123/topics/new")

      assert_redirect(lv, ~p"/controls/courses")
    end

    test "form should render errors on change.", %{
      conn: conn,
      course: course,
      lesson: lesson
    } do
      {:ok, lv, _} =
        live(conn, ~p"/controls/courses/#{course.id}/lessons/#{lesson.id}/topics/new")

      render_async(lv)

      render_result =
        lv
        |> form("#topic-form", %{
          "topic" => %{
            "title" => ""
          }
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
        live(conn, ~p"/controls/courses/#{course.id}/lessons/#{lesson.id}/topics/new")

      render_async(lv)

      render_result =
        lv
        |> form("#topic-form", %{
          "topic" => %{
            "title" => ""
          }
        })
        |> render_submit()

      assert render_result =~ "can&#39;t be blank"
    end

    test "should redirect to the course lessons page when the topic data is valid.", %{
      conn: conn,
      course: course,
      lesson: lesson
    } do
      {:ok, lv, _} =
        live(conn, ~p"/controls/courses/#{course.id}/lessons/#{lesson.id}/topics/new")

      render_async(lv)

      render_result =
        lv
        |> form("#topic-form", %{
          "topic" => %{
            "title" => "Topic1"
          }
        })
        |> render_submit()

      assert render_result =~ "Topic1"
    end
  end

  describe "edit topic" do
    setup :register_and_log_in_user

    setup do
      course = course_fixture()
      lesson = lesson_fixture(course)
      topic = text_topic_fixture(lesson)

      %{course: course, lesson: lesson, topic: topic}
    end

    test "should redirect if the topic id is invalid.", %{
      conn: conn,
      course: course,
      lesson: lesson
    } do
      {:ok, lv, _} =
        live(conn, ~p"/controls/courses/#{course.id}/lessons/#{lesson.id}/topics/invalid/edit")

      assert_redirect(lv, ~p"/controls/courses")
    end

    test "should redirect if the topic cannot be found.", %{
      conn: conn,
      course: course,
      lesson: lesson
    } do
      {:ok, lv, _} =
        live(conn, ~p"/controls/courses/#{course.id}/lessons/#{lesson.id}/topics/5000000000/edit")

      assert_redirect(lv, ~p"/controls/courses")
    end

    test "form should render errors on change.", %{
      conn: conn,
      course: course,
      lesson: lesson,
      topic: topic
    } do
      {:ok, lv, _} =
        live(
          conn,
          ~p"/controls/courses/#{course.id}/lessons/#{lesson.id}/topics/#{topic.id}/edit"
        )

      render_async(lv)

      render_result =
        lv
        |> form("#topic-form", %{
          "topic" => %{
            "title" => ""
          }
        })
        |> render_change()

      assert render_result =~ "can&#39;t be blank"
    end

    test "form should render errors on submit.", %{
      conn: conn,
      course: course,
      lesson: lesson,
      topic: topic
    } do
      {:ok, lv, _} =
        live(
          conn,
          ~p"/controls/courses/#{course.id}/lessons/#{lesson.id}/topics/#{topic.id}/edit"
        )

      render_async(lv)

      render_result =
        lv
        |> form("#topic-form", %{
          "topic" => %{
            "title" => ""
          }
        })
        |> render_submit()

      assert render_result =~ "can&#39;t be blank"
    end

    test "should redirect to the course lessons page when the topic data is valid.", %{
      conn: conn,
      course: course,
      lesson: lesson,
      topic: topic
    } do
      {:ok, lv, _} =
        live(
          conn,
          ~p"/controls/courses/#{course.id}/lessons/#{lesson.id}/topics/#{topic.id}/edit"
        )

      render_async(lv)

        lv
        |> form("#topic-form", %{
          "topic" => %{
            "title" => "kool kyle"
          }
        })
        |> render_submit()

      assert_redirect(lv, ~p"/controls/courses/#{course.id}/lessons/#{lesson.id}")
    end
  end
end
