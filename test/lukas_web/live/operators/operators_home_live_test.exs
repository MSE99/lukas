defmodule LukasWeb.Operators.HomeLiveTest do
  use LukasWeb.ConnCase

  import Phoenix.LiveViewTest

  test "should require an authenticated operator", %{conn: conn} do
    assert {:error, {:redirect, _}} = live(conn, ~p"/controls")
  end

  test "should redirect if student tried to visit operators views.", ctx do
    %{conn: conn} = register_and_log_in_student(ctx)
    assert {:error, {:redirect, _}} = live(conn, ~p"/controls")
  end

  test "should redirect if lecturer tried to visit operators views.", ctx do
    %{conn: conn} = register_and_log_in_lecturer(ctx)
    assert {:error, {:redirect, _}} = live(conn, ~p"/controls")
  end
end
