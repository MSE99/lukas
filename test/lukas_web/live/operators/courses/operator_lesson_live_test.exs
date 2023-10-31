defmodule LukasWeb.Operator.LessonLiveTest do
  use LukasWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lukas.LearningFixtures

  alias Lukas.Learning.Course.Content

  test "should require an authenticated admin.", %{conn: conn} do
    assert {:error, {:redirect, _}} = live(conn, ~p"/controls/courses/15/lessons/10")
  end

  def setup_test(ctx) do
    course = course_fixture()

    lesson =
      lesson_fixture(course, %{
        "title" => "Operations",
        "description" => "a lesson about operations"
      })

    topic1 = text_topic_fixture(lesson, %{"title" => "Topic 1", "content" => "Topic 1"})
    topic2 = text_topic_fixture(lesson, %{"title" => "Topic 2", "content" => "Topic 2"})
    topic3 = text_topic_fixture(lesson, %{"title" => "Topic 3", "content" => "Topic 3"})

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

    test "should react to lesson being updated.", %{conn: conn, lesson: lesson} do
      {:ok, lv, html} = live(conn, ~p"/controls/courses/#{lesson.course_id}/lessons/#{lesson.id}")

      assert html =~ lesson.title

      {:ok, next_lesson} =
        Content.update_lesson(lesson, %{title: "New title", description: "new description"})

      assert render(lv) =~ next_lesson.title
    end

    test "should render a button for removing topics.", %{conn: conn, lesson: lesson} do
      {:ok, lv, _html} =
        live(conn, ~p"/controls/courses/#{lesson.course_id}/lessons/#{lesson.id}")

      topic = text_topic_fixture(lesson)

      lv |> element("#delete-topic-#{topic.id}") |> render_click()

      refute render(lv) =~ topic.title
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

    test "should create a new video topic.", %{
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
          "kind" => "video"
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
      {:ok, _} = Content.remove_topic(topic1)
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
        Content.update_topic(topic1, %{
          "title" => "Bar",
          "content" => "bar is great foo is none",
          "kind" => "text"
        })

      refute render(lv) =~ topic1.title
      assert render(lv) =~ updated_topic.title
    end
  end

  describe "edit topic" do
    setup [:register_and_log_in_user, :setup_test]

    test "should redirect if the lesson id is invalid.", %{conn: conn, course: course} do
      assert {:error, {:redirect, _}} =
               live(conn, ~p"/controls/courses/#{course.id}/lessons/invalid")
    end

    test "form should render errors on change.", %{
      conn: conn,
      course: course,
      lesson: lesson,
      topics: [topic1 | _]
    } do
      {:ok, lv, _html} =
        live(
          conn,
          ~p"/controls/courses/#{course.id}/lessons/#{lesson.id}/topics/#{topic1.id}/edit-topic"
        )

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
      course: course,
      lesson: lesson,
      topics: [topic1 | _]
    } do
      {:ok, lv, _html} =
        live(
          conn,
          ~p"/controls/courses/#{course.id}/lessons/#{lesson.id}/topics/#{topic1.id}/edit-topic"
        )

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

    test "should edit the text topic.", %{
      conn: conn,
      course: course,
      lesson: lesson,
      topics: [topic1 | _],
      path: path
    } do
      {:ok, lv, _html} =
        live(
          conn,
          ~p"/controls/courses/#{course.id}/lessons/#{lesson.id}/topics/#{topic1.id}/edit-topic"
        )

      lv
      |> form("form", %{
        "topic" => %{
          "title" => "Nib",
          "content" => "Foo is great bar is none.",
          "kind" => "text"
        }
      })
      |> render_submit()

      assert_patched(lv, path)
      refute render(lv) =~ topic1.title
      assert render(lv) =~ "Nib"
    end
  end
end
