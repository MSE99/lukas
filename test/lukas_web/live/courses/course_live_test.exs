defmodule LukasWeb.Courses.CourseLiveTest do
  use LukasWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lukas.LearningFixtures

  def create_course(ctx) do
    Map.put(ctx, :course, course_fixture())
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

    test "should render the course name if the course id is valid.", %{conn: conn, course: course} do
      {:ok, _, html} = live(conn, ~p"/controls/courses/#{course.id}")
      assert html =~ course.name
    end
  end
end
