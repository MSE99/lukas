defmodule LukasWeb.Operator.LessonLiveTest do
  use LukasWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lukas.LearningFixtures

  alias Lukas.Learning

  test "should require an authenticated admin.", %{conn: conn} do
    assert {:error, {:redirect, _}} = live(conn, ~p"/controls/courses/15/lessons/10")
  end

  def setup_test(ctx) do
    course = course_fixture()

    {:ok, lesson} =
      Learning.create_lesson(course, %{
        "title" => "Operations",
        "description" => "a lesson about operations"
      })

    {:ok, topic1} =
      Learning.create_text_topic(lesson, %{"title" => "Topic 1", "content" => "Topic 1"})

    {:ok, topic2} =
      Learning.create_text_topic(lesson, %{"title" => "Topic 2", "content" => "Topic 2"})

    {:ok, topic3} =
      Learning.create_text_topic(lesson, %{"title" => "Topic 3", "content" => "Topic 3"})

    Map.merge(
      ctx,
      %{
        course: course,
        lesson: lesson,
        topics: [topic1, topic2, topic3],
        path: ~p"/controls/courses/#{course.id}/lessons/#{lesson.id}"
      }
    )
  end

  describe "index" do
    setup [:register_and_log_in_user, :setup_test]

    test "should redirect if the lesson id is invalid.", %{conn: conn, course: course} do
      assert {:error, {:redirect, _}} =
               live(conn, ~p"/controls/courses/#{course.id}/lessons/invalid")
    end

    test "should render the lesson name and the topics.", %{
      conn: conn,
      course: course,
      lesson: lesson,
      topics: topics,
      path: path
    } do
      {:ok, _lv, html} = live(conn, path)

      assert html =~ lesson.title
      assert html =~ lesson.description

      Enum.each(topics, fn topic -> assert html =~ topic.title end)
    end
  end
end
