defmodule LukasWeb.Lecturers.HomeLiveTest do
  use LukasWeb.ConnCase

  import Phoenix.LiveViewTest

  test "should require an authenticated lecturer", %{conn: conn} do
    assert {:error, {:redirect, _}} = live(conn, ~p"/tutor")
  end

  test "should redirect if student tried to visit operators views.", ctx do
    %{conn: conn} = register_and_log_in_student(ctx)
    assert {:error, {:redirect, _}} = live(conn, ~p"/tutor")
  end

  test "should redirect if operator tried to visit operators views.", ctx do
    %{conn: conn} = register_and_log_in_user(ctx)
    assert {:error, {:redirect, _}} = live(conn, ~p"/tutor")
  end
end
