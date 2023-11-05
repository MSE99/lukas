defmodule LukasWeb.Shared.CoursesLiveTest do
  use LukasWeb.ConnCase

  import Phoenix.LiveViewTest

  test "should redirect if the user is authenticated.", ctx do
    %{conn: student_conn} = register_and_log_in_student(ctx)
    %{conn: lecturer_conn} = register_and_log_in_lecturer(ctx)
    %{conn: operator_conn} = register_and_log_in_user(ctx)

    assert {:error, {:redirect, _}} = live(student_conn, ~p"/courses")
    assert {:error, {:redirect, _}} = live(lecturer_conn, ~p"/courses")
    assert {:error, {:redirect, _}} = live(operator_conn, ~p"/courses")
  end
end
