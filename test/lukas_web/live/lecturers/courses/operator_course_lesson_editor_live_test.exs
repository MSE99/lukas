defmodule LukasWeb.Operator.LessonEditorLiveTest do
  use LukasWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Lukas.LearningFixtures

  describe "editor view" do
    setup ctx do
      register_and_log_in_user(ctx)
    end

    test "should redirect if the course if is invalid.", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/controls/courses/foo/lessons/editor")
      assert_redirect(lv, ~p"/controls/courses", 3500)
    end

    test "should render the editor if the course exists.", %{conn: conn} do
      course = course_fixture()

      {:ok, lv, _html} = live(conn, ~p"/controls/courses/#{course.id}/lessons/editor")
      render_async(lv)

      assert lv |> element("#lesson-editor") |> has_element?()
    end
  end
end
