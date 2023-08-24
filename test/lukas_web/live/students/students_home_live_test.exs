defmodule LukasWeb.Students.HomeLiveTest do
  use LukasWeb.ConnCase

  import Phoenix.LiveViewTest

  test "should require an authenticated student", %{conn: conn} do
    assert {:error, {:redirect, _}} = live(conn, ~p"/home")
  end

  test "should redirect if lecturer tried to visit operators views.", ctx do
    %{conn: conn} = register_and_log_in_lecturer(ctx)
    assert {:error, {:redirect, _}} = live(conn, ~p"/home")
  end

  test "should redirect if operator tried to visit operators views.", ctx do
    %{conn: conn} = register_and_log_in_user(ctx)
    assert {:error, {:redirect, _}} = live(conn, ~p"/home")
  end
end
