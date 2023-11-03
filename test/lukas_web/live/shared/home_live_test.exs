defmodule LukasWeb.Shared.HomeLiveTest do
  use LukasWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Lukas.LearningFixtures

  test "should redirect if the user is authenticated.", ctx do
    %{conn: student_conn} = register_and_log_in_student(ctx)
    %{conn: lecturer_conn} = register_and_log_in_lecturer(ctx)
    %{conn: operator_conn} = register_and_log_in_user(ctx)

    assert {:error, {:redirect, _}} = live(student_conn, ~p"/")
    assert {:error, {:redirect, _}} = live(lecturer_conn, ~p"/")
    assert {:error, {:redirect, _}} = live(operator_conn, ~p"/")
  end

  test "should render 10 free & 10 paid courses.",
       %{conn: conn} do
    paid = 1..10 |> Enum.map(fn _ -> course_fixture() end)
    free = 1..10 |> Enum.map(fn _ -> course_fixture(%{price: 0.0}) end)

    {:ok, lv, _html} = live(conn, ~p"/")

    html = render_async(lv)

    paid
    |> Enum.each(fn c -> assert html =~ c.name end)

    free
    |> Enum.each(fn c -> assert html =~ c.name end)
  end
end
