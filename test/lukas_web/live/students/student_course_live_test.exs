defmodule LukasWeb.Students.StudentCourseLiveTest do
  use LukasWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lukas.LearningFixtures
  import Lukas.AccountsFixtures

  alias Lukas.Learning
  alias Lukas.Learning.Course
  alias Lukas.Learning.Course.Students

  def setup_course(ctx) do
    course = course_fixture()
    lecturers = [lecturer_fixture(), lecturer_fixture(), lecturer_fixture()]
    tags = [tag_fixture(), tag_fixture()]

    Enum.each(lecturers, fn lect -> Course.Staff.add_lecturer_to_course(course, lect) end)
    Enum.each(tags, fn tag -> Learning.tag_course(course.id, tag.id) end)

    Map.merge(ctx, %{course: course, lecturers: lecturers, tags: tags})
  end

  test "should require an authenticated student", %{conn: conn} do
    assert {:error, {:redirect, _}} = live(conn, ~p"/home/courses/10")
  end

  describe "unenrolled" do
    setup [:register_and_log_in_student, :setup_course]

    test "should render the course name and lecturers.", %{
      conn: conn,
      course: course,
      lecturers: lecturers,
      tags: tags
    } do
      {:ok, _, html} = live(conn, ~p"/home/courses/#{course.id}")

      assert html =~ course.name
      Enum.each(lecturers, fn lect -> assert html =~ lect.name end)
      Enum.each(tags, fn tag -> assert html =~ tag.name end)
    end

    test "should react to course being updated.", %{
      conn: conn,
      course: course
    } do
      {:ok, lv, _} = live(conn, ~p"/home/courses/#{course.id}")

      {:ok, updated_course} =
        Learning.update_course(course, %{
          "name" => "cool course",
          "description" => "nice course name"
        })

      assert render(lv) =~ updated_course.name
    end

    test "should react to lecturers being added and removed.", %{
      conn: conn,
      course: course,
      lecturers: lecturers
    } do
      {:ok, lv, _} = live(conn, ~p"/home/courses/#{course.id}")

      Enum.each(lecturers, fn lect ->
        Learning.Course.Staff.remove_lecturer_from_course(course, lect)
      end)

      new_lecturers = [
        lecturer_fixture(),
        lecturer_fixture(),
        lecturer_fixture(),
        lecturer_fixture()
      ]

      Enum.each(new_lecturers, fn lect -> Course.Staff.add_lecturer_to_course(course, lect) end)

      html = render(lv)

      Enum.each(lecturers, fn lect -> refute html =~ lect.name end)
      Enum.each(new_lecturers, fn lect -> assert html =~ lect.name end)
    end

    test "should react to tags being added and removed.", %{
      conn: conn,
      course: course,
      tags: tags
    } do
      {:ok, lv, _} = live(conn, ~p"/home/courses/#{course.id}")

      Enum.each(tags, fn tag -> Learning.untag_course(course.id, tag.id) end)

      new_tags = [
        tag_fixture(),
        tag_fixture(),
        tag_fixture(),
        tag_fixture()
      ]

      Enum.each(new_tags, fn tag -> Learning.tag_course(course.id, tag.id) end)

      html = render(lv)

      Enum.each(tags, fn tag -> refute html =~ tag.name end)
      Enum.each(new_tags, fn tag -> assert html =~ tag.name end)
    end

    test "should ignore other messages", %{conn: conn, course: course} do
      {:ok, lv, _} = live(conn, ~p"/home/courses/#{course.id}")
      lesson_fixture(course)
      assert render(lv) =~ course.name
    end

    test "should render the enroll button if the student is not enrolled", %{
      conn: conn,
      course: course
    } do
      {:ok, lv, _} = live(conn, ~p"/home/courses/#{course.id}")
      assert lv |> element("button#enroll-button") |> has_element?()
    end

    test "should not render the enroll button if the student is enrolled", %{
      conn: conn,
      course: course,
      user: user
    } do
      {:ok, _} = Students.enroll_student(course, user)
      {:ok, lv, _} = live(conn, ~p"/home/courses/#{course.id}")
      refute lv |> element("button#enroll-button") |> has_element?()
    end

    test "should react to student being enrolled in the course and remove the enroll button.", %{
      conn: conn,
      course: course,
      user: user
    } do
      {:ok, lv, _} = live(conn, ~p"/home/courses/#{course.id}")
      assert lv |> element("button#enroll-button") |> has_element?()
      {:ok, _} = Students.enroll_student(course, user)
      refute lv |> element("button#enroll-button") |> has_element?()
    end
  end
end
