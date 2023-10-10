defmodule LukasWeb.Operator.LecturerLiveTest do
  use LukasWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lukas.AccountsFixtures
  import Lukas.LearningFixtures

  alias Lukas.Learning.Course.Staff

  setup :register_and_log_in_user

  setup do
    %{lecturer: lecturer_fixture()}
  end

  test "should redirect if the id is invalid.", %{conn: conn} do
    assert {:error, {:redirect, _}} = live(conn, ~p"/controls/lecturers/INVALID")
  end

  test "should redirect if no lecturer has the given ID.", %{conn: conn} do
    assert {:error, {:redirect, _}} = live(conn, ~p"/controls/lecturers/1500")
  end

  test "should render the information about the lecturer.", %{conn: conn, lecturer: lect} do
    course1 = course_fixture()
    course2 = course_fixture()

    Staff.add_lecturer_to_course(course1, lect)
    Staff.add_lecturer_to_course(course2, lect)

    {:ok, lv, _html} = live(conn, ~p"/controls/lecturers/#{lect.id}")

    html = render_async(lv)

    assert html =~ lect.name
    assert html =~ course1.name
    assert html =~ course2.name
  end

  test "should render a button for disabling/enabling the lecturer.", %{
    conn: conn,
    lecturer: lect
  } do
    {:ok, lv, _html} = live(conn, ~p"/controls/lecturers/#{lect.id}")

    render_async(lv)

    lv |> element("button#disable-lecturer") |> render_click()
    refute Lukas.Accounts.get_lecturer!(lect.id).enabled

    lv |> element("button#enable-lecturer") |> render_click()
    assert Lukas.Accounts.get_lecturer!(lect.id).enabled
  end

  test "should react to the lecturer being updated.", %{
    conn: conn,
    lecturer: lect
  } do
    {:ok, lv, _html} = live(conn, ~p"/controls/lecturers/#{lect.id}")

    render_async(lv)

    {:ok, _} = Lukas.Accounts.disable_user(lect)

    assert lv
           |> element("button#enable-lecturer")
           |> has_element?()
  end
end
