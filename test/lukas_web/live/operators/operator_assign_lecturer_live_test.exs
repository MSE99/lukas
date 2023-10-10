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

  test "should render the course name and a list of all available/assigned lecturers.", %{
    conn: conn,
    course: course
  } do
    lect1 = lecturer_fixture()
    lect2 = lecturer_fixture()
    lect3 = lecturer_fixture()

    Staff.add_lecturer_to_course(course, lect3)

    {:ok, lv, _} = live(conn, ~p"/controls/courses/#{course.id}/assign-lecturer")

    html = render_async(lv)

    assert html =~ lect1.name
    assert html =~ lect2.name
    assert html =~ lect3.name

    assert lv |> element("#available-#{lect1.id}") |> has_element?()
    assert lv |> element("#available-#{lect2.id}") |> has_element?()
    assert lv |> element("#assigned-#{lect3.id}") |> has_element?()
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

  test "should react to lecturers being assigned to the course.", %{
    conn: conn,
    course: course
  } do
    {:ok, lv, _} = live(conn, ~p"/controls/courses/#{course.id}/assign-lecturer")
    render_async(lv)

    lect1 = lecturer_fixture()
    lect2 = lecturer_fixture()
    lect3 = lecturer_fixture()

    Staff.add_lecturer_to_course(course, lect3)

    html = render_async(lv)

    assert html =~ lect1.name
    assert html =~ lect2.name
    assert html =~ lect3.name

    assert lv |> element("#available-#{lect1.id}") |> has_element?()
    assert lv |> element("#available-#{lect2.id}") |> has_element?()
    assert lv |> element("#assigned-#{lect3.id}") |> has_element?()
  end

  test "should react to lecturers being disabled.", %{
    conn: conn,
    course: course
  } do
    {:ok, lv, _} = live(conn, ~p"/controls/courses/#{course.id}/assign-lecturer")
    render_async(lv)

    lect1 = lecturer_fixture()
    lect2 = lecturer_fixture()
    lect3 = lecturer_fixture()

    Staff.add_lecturer_to_course(course, lect3)

    html = render_async(lv)
    assert html =~ lect1.name
    assert html =~ lect2.name

    assert lv |> element("#available-#{lect1.id}") |> has_element?()
    assert lv |> element("#available-#{lect2.id}") |> has_element?()
    assert lv |> element("#assigned-#{lect3.id}") |> has_element?()

    Accounts.disable_user(lect1)
    Accounts.disable_user(lect3)

    post_disable_html = render(lv)
    assert post_disable_html =~ lect2.name

    refute post_disable_html =~ lect1.name
    refute post_disable_html =~ lect3.name
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

    assert lv |> element("#available-#{lect1.id}") |> has_element?()
    assert lv |> element("#available-#{lect2.id}") |> has_element?()

    Staff.add_lecturer_to_course(course, lect1)

    post_add_html = render(lv)
    assert post_add_html =~ lect1.name
    assert post_add_html =~ lect2.name

    assert lv |> element("#assigned-#{lect1.id}") |> has_element?()
    assert lv |> element("#available-#{lect2.id}") |> has_element?()

    Staff.remove_lecturer_from_course(course, lect1)

    post_remove_html = render(lv)
    assert post_remove_html =~ lect1.name
    assert post_remove_html =~ lect2.name

    assert lv |> element("#available-#{lect1.id}") |> has_element?()
    assert lv |> element("#available-#{lect2.id}") |> has_element?()
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

  test "should render buttons for adding/removing a lecturer to the course.", %{
    conn: conn,
    course: course
  } do
    lect1 = lecturer_fixture()
    lect2 = lecturer_fixture()

    {:ok, lv, _} = live(conn, ~p"/controls/courses/#{course.id}/assign-lecturer")
    render_async(lv)

    lv |> element("button#assign-lecturer-#{lect1.id}") |> render_click()

    assert [^lect1] = Staff.list_course_lecturers(course)

    assert lv |> element("#assigned-#{lect1.id}") |> has_element?()
    assert lv |> element("#available-#{lect2.id}") |> has_element?()

    lv |> element("button#unassign-lecturer-#{lect1.id}") |> render_click()

    assert lv |> element("#available-#{lect1.id}") |> has_element?()
    refute lv |> element("#assigned-#{lect1.id}") |> has_element?()

    assert lv |> element("#available-#{lect2.id}") |> has_element?()
  end
end
