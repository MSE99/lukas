defmodule LukasWeb.Public.CourseLiveTest do
  use LukasWeb.ConnCase, async: true

  alias Lukas.Learning

  import Phoenix.LiveViewTest
  import Lukas.LearningFixtures
  import Lukas.AccountsFixtures

  test "should redirect if the user is authenticated.", ctx do
    %{conn: opr_conn} = register_and_log_in_user(ctx)
    %{conn: student_conn} = register_and_log_in_student(ctx)
    %{conn: lecturer_conn} = register_and_log_in_lecturer(ctx)

    assert {:error, {:redirect, _}} = live(opr_conn, ~p"/courses/500")
    assert {:error, {:redirect, _}} = live(student_conn, ~p"/courses/500")
    assert {:error, {:redirect, _}} = live(lecturer_conn, ~p"/courses/500")
  end

  test "should immediately redirect if the process id is invalid.", %{conn: conn} do
    assert {:error, {:redirect, _}} = live(conn, ~p"/courses/INVALID")
  end

  test "should redirect if the course id is valid but matches no course.", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/courses/300")
    assert_redirect(lv, ~p"/")
  end

  test "should render the course name and the price and lecturers.", %{conn: conn} do
    course = course_fixture()

    lect1 = lecturer_fixture()
    lect2 = lecturer_fixture()
    lect3 = lecturer_fixture()

    {:ok, _} = Learning.Course.Staff.add_lecturer_to_course(course, lect1)
    {:ok, _} = Learning.Course.Staff.add_lecturer_to_course(course, lect2)
    {:ok, _} = Learning.Course.Staff.add_lecturer_to_course(course, lect3)

    t1 = tag_fixture()
    t2 = tag_fixture()
    t3 = tag_fixture()

    {:ok, _} = Learning.tag_course(course.id, t1.id)
    {:ok, _} = Learning.tag_course(course.id, t2.id)
    {:ok, _} = Learning.tag_course(course.id, t3.id)

    {:ok, lv, _html} = live(conn, ~p"/courses/#{course.id}")

    html = render_async(lv)

    assert html =~ course.name
    assert html =~ "#{course.price} LYD"

    assert html =~ lect1.name
    assert html =~ lect2.name
    assert html =~ lect3.name

    assert html =~ t1.name
    assert html =~ t2.name
    assert html =~ t3.name
  end

  test "should react to course being updated.", %{conn: conn} do
    course = course_fixture()

    {:ok, lv, _html} = live(conn, ~p"/courses/#{course.id}")

    html = render_async(lv)

    assert html =~ course.name
    assert html =~ "#{course.price |> :erlang.float_to_binary(decimals: 1)} LYD"

    {:ok, updated} = Learning.update_course(course, %{"price" => 600})

    assert render(lv) =~ "#{updated.price |> :erlang.float_to_binary(decimals: 1)} LYD"
  end

  test "should react to lecturer being added to course.", %{conn: conn} do
    course = course_fixture()

    {:ok, lv, _html} = live(conn, ~p"/courses/#{course.id}")

    html = render_async(lv)
    assert html =~ course.name

    lect = lecturer_fixture()
    {:ok, _} = Learning.Course.Staff.add_lecturer_to_course(course, lect)

    assert render(lv) =~ lect.name
  end

  test "should react to lecturer being removed from course.", %{conn: conn} do
    course = course_fixture()

    lect = lecturer_fixture()
    {:ok, _} = Learning.Course.Staff.add_lecturer_to_course(course, lect)

    {:ok, lv, _html} = live(conn, ~p"/courses/#{course.id}")

    html = render_async(lv)

    assert html =~ course.name
    assert html =~ lect.name

    Learning.Course.Staff.remove_lecturer_from_course(course, lect)

    refute render(lv) =~ lect.name
  end
end
