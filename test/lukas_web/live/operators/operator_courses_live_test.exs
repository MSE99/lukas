defmodule LukasWeb.Operator.AllCoursesLiveTest do
  use LukasWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lukas.LearningFixtures

  alias Lukas.Learning

  test "should require an authenticated operator.", %{conn: conn} do
    assert {:error, {:redirect, _}} = live(conn, ~p"/controls/courses")
  end

  test "should redirect if the user is a student.", ctx do
    %{conn: conn} = register_and_log_in_student(ctx)
    assert {:error, {:redirect, _}} = live(conn, ~p"/controls/courses")
  end

  describe "index" do
    setup [:register_and_log_in_user]

    test "should render all courses.", %{conn: conn} do
      courses = 1..50 |> Enum.map(fn _ -> course_fixture() end)

      {:ok, lv, _} = live(conn, ~p"/controls/courses")

      html = render_async(lv)
      Enum.each(courses, fn %{name: name} -> assert html =~ name end)
    end

    test "should react to courses being added.", %{conn: conn} do
      {:ok, lv, _} = live(conn, ~p"/controls/courses")

      courses = Enum.map(1..50, fn _ -> course_fixture() end)

      html = render(lv)
      Enum.each(courses, fn %{name: name} -> assert html =~ name end)
    end

    test "should react to courses being updated.", %{conn: conn} do
      {:ok, lv, _} = live(conn, ~p"/controls/courses")

      course = course_fixture()
      assert render(lv) =~ course.name

      Lukas.Learning.update_course(course, %{name: "Updated foo bar baz"})

      assert render(lv) =~ "Updated foo bar baz"
    end
  end

  describe "new" do
    setup [:register_and_log_in_user]

    test "should render errors on change.", %{conn: conn} do
      tag1 = tag_fixture()
      tag2 = tag_fixture()
      tag3 = tag_fixture()

      {:ok, lv, _} = live(conn, ~p"/controls/courses/new")

      lv |> element("span", tag1.name) |> render_click()
      lv |> element("span", tag2.name) |> render_click()
      lv |> element("span", tag3.name) |> render_click()

      render_result =
        lv
        |> form("form", %{"course" => %{"name" => ""}})
        |> render_change()

      assert render_result =~ "can&#39;t be blank"
    end

    test "should render errors on submit.", %{conn: conn} do
      tag1 = tag_fixture()
      tag2 = tag_fixture()
      tag3 = tag_fixture()

      {:ok, lv, _} = live(conn, ~p"/controls/courses/new")

      lv |> element("span", tag1.name) |> render_click()
      lv |> element("span", tag2.name) |> render_click()
      lv |> element("span", tag3.name) |> render_click()

      render_result =
        lv
        |> form("form", %{"course" => %{"name" => ""}})
        |> render_submit()

      assert render_result =~ "can&#39;t be blank"
    end

    test "should create new course and patch to the courses liveview.", %{conn: conn} do
      tag1 = tag_fixture()
      tag2 = tag_fixture()
      tag3 = tag_fixture()

      {:ok, lv, _} = live(conn, ~p"/controls/courses/new")

      lv |> element("span", tag1.name) |> render_click()
      lv |> element("span", tag2.name) |> render_click()
      lv |> element("span", tag3.name) |> render_click()

      lv
      |> form("form", %{"course" => %{"name" => "foo bar baz", "price" => 500}})
      |> render_submit()

      assert_patched(lv, ~p"/controls/courses")

      assert render(lv) =~ "foo bar baz"

      [course] = Learning.list_courses()

      assert Enum.find(course.tags, fn t -> t.tag_id == tag1.id end)
      assert Enum.find(course.tags, fn t -> t.tag_id == tag2.id end)
      assert Enum.find(course.tags, fn t -> t.tag_id == tag3.id end)
    end
  end
end
