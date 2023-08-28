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
        path: ~p"/controls/courses/#{course.id}/lessons/#{lesson.id}",
        new_topic_path: ~p"/controls/courses/#{course.id}/lessons/#{lesson.id}/new-topic"
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
      lesson: lesson,
      topics: topics,
      path: path
    } do
      {:ok, _lv, html} = live(conn, path)

      assert html =~ lesson.title
      assert html =~ lesson.description

      Enum.each(topics, fn topic -> assert html =~ topic.title end)
    end

    test "should render a button for adding new topics.", %{
      conn: conn,
      path: path,
      lesson: lesson
    } do
      {:ok, lv, _html} = live(conn, path)
      lv |> element("a", "New topic") |> render_click()
      assert_patched(lv, ~p"/controls/courses/#{lesson.course_id}/lessons/#{lesson.id}/new-topic")
    end
  end

  describe "new" do
    setup [:register_and_log_in_user, :setup_test]

    test "should redirect if the lesson id is invalid.", %{conn: conn, course: course} do
      assert {:error, {:redirect, _}} =
               live(conn, ~p"/controls/courses/#{course.id}/lessons/invalid")
    end

    test "form should render errors on change.", %{
      conn: conn,
      new_topic_path: new_topic_path
    } do
      {:ok, lv, _html} = live(conn, new_topic_path)

      render_result =
        lv
        |> form("form", %{
          "topic" => %{
            "title" => "",
            "content" => "Foo is great bar is none.",
            "kind" => "text"
          }
        })
        |> render_change()

      assert render_result =~ "can&#39;t be blank"
    end

    test "form should render errors on submit.", %{
      conn: conn,
      new_topic_path: new_topic_path
    } do
      {:ok, lv, _html} = live(conn, new_topic_path)

      render_result =
        lv
        |> form("form", %{
          "topic" => %{
            "title" => "",
            "content" => "Foo is great bar is none.",
            "kind" => "text"
          }
        })
        |> render_submit()

      assert render_result =~ "can&#39;t be blank"
    end

    test "should create a new text topic.", %{
      conn: conn,
      new_topic_path: new_topic_path,
      path: path
    } do
      {:ok, lv, _html} = live(conn, new_topic_path)

      lv
      |> form("form", %{
        "topic" => %{
          "title" => "Foo",
          "content" => "Foo is great bar is none.",
          "kind" => "text"
        }
      })
      |> render_submit()

      assert_patched(lv, path)
      assert render(lv) =~ "Foo"
    end

    test "should react to topics being removed.", %{
      conn: conn,
      path: path,
      topics: [topic1 | _]
    } do
      {:ok, lv, _html} = live(conn, path)
      assert render(lv) =~ topic1.title
      {:ok, _} = Learning.remove_topic(topic1)
      refute render(lv) =~ topic1.title
    end

    test "should react to topics being updated.", %{
      conn: conn,
      path: path,
      topics: [topic1 | _]
    } do
      {:ok, lv, _html} = live(conn, path)
      assert render(lv) =~ topic1.title

      {:ok, updated_topic} =
        Learning.update_topic(topic1, %{
          "title" => "Bar",
          "content" => "bar is great foo is none",
          "kind" => "text"
        })

      refute render(lv) =~ topic1.title
      assert render(lv) =~ updated_topic.title
    end
  end
end
