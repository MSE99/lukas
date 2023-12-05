defmodule LukasWeb.Operator.StatsLiveTest do
  use LukasWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Lukas.LearningFixtures

  setup :register_and_log_in_user

  describe "basic stats" do
    test "should render the number of courses in the system and the current profits.", %{
      conn: conn
    } do
      course_fixture()
      course_fixture()
      course_fixture()

      {:ok, lv, _html} = live(conn, ~p"/controls/stats")

      render_async(lv)
    end
  end
end
