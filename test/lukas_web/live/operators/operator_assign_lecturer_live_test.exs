defmodule LukasWeb.Operator.AssignLecturerLiveTest do
  use LukasWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lukas.LearningFixtures
  import Lukas.AccountsFixtures

  alias Lukas.Accounts
  alias Lukas.Learning
  alias Lukas.Learning.Course.Staff

  setup :register_and_log_in_user

  setup do
    %{course: course_fixture()}
  end

  test "should redirect if the course id is invalid.", %{conn: conn} do
    assert {:error, {:redirect, _}} = live(conn, ~p"/controls/courses/FOO/assign-lecturer")
  end

  test "should redirect if no course has the given id.", %{conn: conn} do
    assert {:error, {:redirect, _}} = live(conn, ~p"/controls/courses/501/assign-lecturer")
  end

  test "should render the course name and a list of all available lecturers.", %{
    conn: conn,
    course: course
  } do
    lect1 = lecturer_fixture()
    lect2 = lecturer_fixture()

    {:ok, lv, _} = live(conn, ~p"/controls/courses/#{course.id}/assign-lecturer")

    html = render_async(lv)

    assert html =~ lect1.name
    assert html =~ lect2.name
  end

  test "should react to lecturers registering.", %{
    conn: conn,
    course: course
  } do
    {:ok, lv, _} = live(conn, ~p"/controls/courses/#{course.id}/assign-lecturer")
    render_async(lv)

    lect1 = lecturer_fixture()
    lect2 = lecturer_fixture()

    html = render_async(lv)
    assert html =~ lect1.name
    assert html =~ lect2.name
  end

  test "should react to lecturers being disabled.", %{
    conn: conn,
    course: course
  } do
    {:ok, lv, _} = live(conn, ~p"/controls/courses/#{course.id}/assign-lecturer")
    render_async(lv)

    lect1 = lecturer_fixture()
    lect2 = lecturer_fixture()

    html = render_async(lv)
    assert html =~ lect1.name
    assert html =~ lect2.name

    Accounts.disable_user(lect1)

    post_disable_html = render(lv)
    refute post_disable_html =~ lect1.name
    assert post_disable_html =~ lect2.name
  end

  test "should react to lecturers being assigned to the course.", %{
    conn: conn,
    course: course
  } do
    {:ok, lv, _} = live(conn, ~p"/controls/courses/#{course.id}/assign-lecturer")
    render_async(lv)

    lect1 = lecturer_fixture()
    lect2 = lecturer_fixture()

    html = render_async(lv)
    assert html =~ lect1.name
    assert html =~ lect2.name

    Staff.add_lecturer_to_course(course, lect1)

    post_add_html = render(lv)
    refute post_add_html =~ lect1.name
    assert post_add_html =~ lect2.name
  end

  test "should react to lecturers being removed from course.", %{
    conn: conn,
    course: course
  } do
    {:ok, lv, _} = live(conn, ~p"/controls/courses/#{course.id}/assign-lecturer")
    render_async(lv)

    lect1 = lecturer_fixture()
    lect2 = lecturer_fixture()

    html = render_async(lv)
    assert html =~ lect1.name
    assert html =~ lect2.name

    Staff.add_lecturer_to_course(course, lect1)

    post_add_html = render(lv)
    refute post_add_html =~ lect1.name
    assert post_add_html =~ lect2.name

    Staff.remove_lecturer_from_course(course, lect1)

    post_remove_html = render(lv)
    assert post_remove_html =~ lect1.name
    assert post_remove_html =~ lect2.name
  end

  test "should react to course being updated.", %{
    conn: conn,
    course: course
  } do
    {:ok, lv, _} = live(conn, ~p"/controls/courses/#{course.id}/assign-lecturer")

    assert render_async(lv) =~ course.name

    {:ok, next} = Learning.update_course(course, %{"name" => "Raphael the amazing turtle"})

    assert render(lv) =~ next.name
    refute render(lv) =~ course.name
  end

  test "should render a button for adding a lecturer to the course.", %{
    conn: conn,
    course: course
  } do
    lect1 = lecturer_fixture()

    {:ok, lv, _} = live(conn, ~p"/controls/courses/#{course.id}/assign-lecturer")
    render_async(lv)

    lv |> element("button#assign-lecturer-#{lect1.id}") |> render_click()

    assert [^lect1] = Staff.list_course_lecturers(course)
    refute render(lv) =~ lect1.name
  end
end
