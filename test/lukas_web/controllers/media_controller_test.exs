defmodule LukasWeb.MediaControllerTest do
  use LukasWeb.ConnCase, async: true

  import Lukas.LearningFixtures

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

  describe "GET /controls/courses/:course_id/banner_image" do
    setup :register_and_log_in_user

    test "should respond with 400 if the course id is invalid.", %{conn: conn} do
      conn
      |> get(~p"/controls/courses/foo/banner")
      |> response(400)
    end

    test "should respond with 400 if the course cannot be found.", %{conn: conn} do
      conn
      |> get(~p"/controls/courses/5000000/banner")
      |> response(400)
    end

    test "should respond with the banner image of the course.", %{conn: conn} do
      wanted =
        Path.join([
          :code.priv_dir(:lukas),
          "static",
          "content",
          "courses",
          "images",
          Lukas.Learning.Course.default_banner_image()
        ])
        |> File.read!()

      course = course_fixture()

      gotten =
        conn
        |> get(~p"/controls/courses/#{course.id}/banner")
        |> response(200)

      assert gotten == wanted
    end
  end
end
