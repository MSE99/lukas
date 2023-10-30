defmodule LukasWeb.Lecturers.CoursesLiveTest do
  use LukasWeb.ConnCase, async: true

  import Lukas.LearningFixtures
  import Phoenix.LiveViewTest

  alias Lukas.Learning

  setup :register_and_log_in_lecturer

  describe "index" do
    test "should render all lecturers courses.", %{conn: conn, user: user} do
      c1 = course_fixture()
      c2 = course_fixture()

      {:ok, _} = Learning.Course.Staff.add_lecturer_to_course(c1, user)
      {:ok, _} = Learning.Course.Staff.add_lecturer_to_course(c2, user)

      not_given = course_fixture()

      {:ok, lv, _} = live(conn, ~p"/tutor/my-courses")

      html = render_async(lv)

      assert html =~ c1.name
      assert html =~ c2.name
      refute html =~ not_given.name
    end

    test "should react to user being added to course.", %{conn: conn, user: user} do
      {:ok, lv, _} = live(conn, ~p"/tutor/my-courses")

      c1 = course_fixture()
      c2 = course_fixture()

      {:ok, _} = Learning.Course.Staff.add_lecturer_to_course(c1, user)
      {:ok, _} = Learning.Course.Staff.add_lecturer_to_course(c2, user)

      not_given = course_fixture()

      html = render(lv)

      assert html =~ c1.name
      assert html =~ c2.name
      refute html =~ not_given.name
    end

    test "should react to user being removed from course.", %{conn: conn, user: user} do
      c1 = course_fixture()
      c2 = course_fixture()
      c3 = course_fixture()

      {:ok, _} = Learning.Course.Staff.add_lecturer_to_course(c1, user)
      {:ok, _} = Learning.Course.Staff.add_lecturer_to_course(c2, user)

      {:ok, lv, _} = live(conn, ~p"/tutor/my-courses")

      {:ok, _} = Learning.Course.Staff.remove_lecturer_from_course(c1, user)
      {:ok, _} = Learning.Course.Staff.remove_lecturer_from_course(c2, user)
      {:ok, _} = Learning.Course.Staff.add_lecturer_to_course(c3, user)

      html = render(lv)

      refute html =~ c1.name
      refute html =~ c2.name

      assert html =~ c3.name
    end
  end

  describe "new" do
    test "should render errors on change.", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/tutor/my-courses/new")

      lv |> form("form", %{"course" => %{"name" => "", "price" => -0.5}}) |> render_change()

      assert render(lv) =~ "can&#39;t be blank"
    end

    test "should render errors on submit.", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/tutor/my-courses/new")

      lv |> form("form", %{"course" => %{"name" => "", "price" => -0.5}}) |> render_submit()

      assert render(lv) =~ "can&#39;t be blank"
      assert render(lv) =~ "must be greater than or equal to 0"
    end

    test "should create new course and patch back to courses page.", %{conn: conn, user: user} do
      wanted_tag1 = tag_fixture()
      wanted_tag2 = tag_fixture()
      unwanted_tag = tag_fixture()

      {:ok, lv, _html} = live(conn, ~p"/tutor/my-courses/new")

      html = render(lv)
      assert html =~ wanted_tag1.name
      assert html =~ wanted_tag2.name
      assert html =~ unwanted_tag.name

      lv |> element("#tags-#{wanted_tag1.id}") |> render_click()
      lv |> element("#tags-#{wanted_tag2.id}") |> render_click()

      lv |> element("#tags-#{unwanted_tag.id}") |> render_click()
      lv |> element("#tags-#{unwanted_tag.id}") |> render_click()

      lv
      |> form("form", %{"course" => %{"name" => "FOO IS GREAT BAR IS NONE!", "price" => 500.0}})
      |> render_submit()

      assert_patched(lv, ~p"/tutor/my-courses")

      assert render(lv) =~ "FOO IS GREAT BAR IS NONE!"

      [course] = Learning.list_courses()

      assert Enum.find(course.tags, fn t -> t.tag_id == wanted_tag1.id end) != nil
      assert Enum.find(course.tags, fn t -> t.tag_id == wanted_tag2.id end) != nil
      assert Enum.find(course.tags, fn t -> t.tag_id == unwanted_tag.id end) == nil
      assert course.price == 500.0

      assert Learning.Course.Staff.list_course_lecturers(course) == [user]
    end
  end

  describe "edit" do
    setup :register_and_log_in_lecturer

    setup %{user: user} do
      course = course_fixture()
      {:ok, _} = Learning.Course.Staff.add_lecturer_to_course(course, user)
      %{course: course}
    end

    test "should render errors on change.", %{conn: conn, course: course} do
      {:ok, lv, _html} = live(conn, ~p"/tutor/my-courses/#{course.id}/edit")

      lv |> form("form", %{"course" => %{"name" => "", "price" => -0.5}}) |> render_change()

      assert render(lv) =~ "can&#39;t be blank"
    end

    test "should render errors on submit.", %{conn: conn, course: course} do
      {:ok, lv, _html} = live(conn, ~p"/tutor/my-courses/#{course.id}/edit")

      lv |> form("form", %{"course" => %{"name" => "", "price" => -0.5}}) |> render_submit()

      assert render(lv) =~ "can&#39;t be blank"
      assert render(lv) =~ "must be greater than or equal to 0"
    end

    test "should create new course and patch back to courses page.", %{
      conn: conn,
      user: user,
      course: course
    } do
      wanted_tag1 = tag_fixture()
      wanted_tag2 = tag_fixture()
      unwanted_tag = tag_fixture()

      {:ok, lv, _html} = live(conn, ~p"/tutor/my-courses/#{course.id}/edit")

      html = render(lv)
      assert html =~ wanted_tag1.name
      assert html =~ wanted_tag2.name
      assert html =~ unwanted_tag.name

      lv |> element("#tags-#{wanted_tag1.id}") |> render_click()
      lv |> element("#tags-#{wanted_tag2.id}") |> render_click()

      lv |> element("#tags-#{unwanted_tag.id}") |> render_click()
      lv |> element("#tags-#{unwanted_tag.id}") |> render_click()

      lv
      |> form("form", %{"course" => %{"name" => "FOO IS GREAT BAR IS NONE!", "price" => 500.0}})
      |> render_submit()

      assert_patched(lv, ~p"/tutor/my-courses")

      assert render(lv) =~ "FOO IS GREAT BAR IS NONE!"

      [course] = Learning.list_courses()

      assert Enum.find(course.tags, fn t -> t.tag_id == wanted_tag1.id end) != nil
      assert Enum.find(course.tags, fn t -> t.tag_id == wanted_tag2.id end) != nil
      assert Enum.find(course.tags, fn t -> t.tag_id == unwanted_tag.id end) == nil
      assert course.price == 500.0

      assert Learning.Course.Staff.list_course_lecturers(course) == [user]
    end
  end
end
