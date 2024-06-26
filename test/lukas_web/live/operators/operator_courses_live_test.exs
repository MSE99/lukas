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

  describe "new" do
    setup [:register_and_log_in_user]

    test "should render errors on change.", %{conn: conn} do
      tag1 = tag_fixture()
      tag2 = tag_fixture()
      tag3 = tag_fixture()

      {:ok, lv, _} = live(conn, ~p"/controls/courses/new")

      lv |> element("#tags-#{tag1.id}") |> render_click()
      lv |> element("#tags-#{tag2.id}") |> render_click()
      lv |> element("#tags-#{tag3.id}") |> render_click()

      render_result =
        lv
        |> form("form#course-form", %{"course" => %{"name" => ""}})
        |> render_change()

      assert render_result =~ "can&#39;t be blank"
    end

    test "should render errors on submit.", %{conn: conn} do
      tag1 = tag_fixture()
      tag2 = tag_fixture()
      tag3 = tag_fixture()

      {:ok, lv, _} = live(conn, ~p"/controls/courses/new")

      lv |> element("#tags-#{tag1.id}") |> render_click()
      lv |> element("#tags-#{tag2.id}") |> render_click()
      lv |> element("#tags-#{tag3.id}") |> render_click()

      render_result =
        lv
        |> form("form#course-form", %{"course" => %{"name" => ""}})
        |> render_submit()

      assert render_result =~ "can&#39;t be blank"
    end

    test "should create new course and patch to the courses liveview.", %{conn: conn} do
      tag1 = tag_fixture()
      tag2 = tag_fixture()
      tag3 = tag_fixture()

      {:ok, lv, _} = live(conn, ~p"/controls/courses/new")
      render_async(lv)

      lv |> element("#tags-#{tag1.id}") |> render_click()
      lv |> element("#tags-#{tag2.id}") |> render_click()
      lv |> element("#tags-#{tag3.id}") |> render_click()

      lv
      |> form("form#course-form", %{"course" => %{"name" => "foo bar baz", "price" => 500}})
      |> render_submit()

      assert_patched(lv, ~p"/controls/courses")

      assert render_async(lv) =~ "foo bar baz"

      [course] = Learning.list_courses()

      assert Enum.find(course.tags, fn t -> t.tag_id == tag1.id end)
      assert Enum.find(course.tags, fn t -> t.tag_id == tag2.id end)
      assert Enum.find(course.tags, fn t -> t.tag_id == tag3.id end)
    end
  end

  describe "edit" do
    setup [:register_and_log_in_user]

    setup do
      %{course: course_fixture()}
    end

    test "should render errors on change.", %{conn: conn, course: course} do
      tag1 = tag_fixture()
      tag2 = tag_fixture()
      tag3 = tag_fixture()

      {:ok, lv, _} = live(conn, ~p"/controls/courses/#{course.id}/edit")

      lv |> element("#tags-#{tag1.id}") |> render_click()
      lv |> element("#tags-#{tag2.id}") |> render_click()
      lv |> element("#tags-#{tag3.id}") |> render_click()

      render_result =
        lv
        |> form("form#course-form", %{"course" => %{"name" => ""}})
        |> render_change()

      assert render_result =~ "can&#39;t be blank"
    end

    test "should render errors on submit.", %{conn: conn, course: course} do
      tag1 = tag_fixture()
      tag2 = tag_fixture()
      tag3 = tag_fixture()

      {:ok, lv, _} = live(conn, ~p"/controls/courses/#{course.id}/edit")

      lv |> element("#tags-#{tag1.id}") |> render_click()
      lv |> element("#tags-#{tag2.id}") |> render_click()
      lv |> element("#tags-#{tag3.id}") |> render_click()

      render_result =
        lv
        |> form("form#course-form", %{"course" => %{"name" => ""}})
        |> render_submit()

      assert render_result =~ "can&#39;t be blank"
    end

    test "should edit course and patch to the courses liveview.", %{conn: conn, course: course} do
      tag1 = tag_fixture()
      tag2 = tag_fixture()
      tag3 = tag_fixture()

      {:ok, lv, _} = live(conn, ~p"/controls/courses/#{course.id}/edit")
      render_async(lv)

      lv |> element("#tags-#{tag1.id}") |> render_click()
      lv |> element("#tags-#{tag2.id}") |> render_click()
      lv |> element("#tags-#{tag3.id}") |> render_click()

      lv
      |> form("form#course-form", %{"course" => %{"name" => "foo bar baz", "price" => 500}})
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
