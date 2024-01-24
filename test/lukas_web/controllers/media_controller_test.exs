defmodule LukasWeb.MediaControllerTest do
  use LukasWeb.ConnCase, async: true

  test "should redirect if the user is not authenticated.", %{conn: conn} do
    conn
    |> post(~p"/media", %{})
    |> response(302)
  end

  test "should redirect if the user is a student.", ctx do
    %{conn: conn} = register_and_log_in_student(ctx)

    conn
    |> post(~p"/media", %{})
    |> response(302)
  end
end
