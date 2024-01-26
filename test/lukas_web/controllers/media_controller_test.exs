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

  describe "GET /controls/courses/:course_id/banner" do
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

  describe "GET /tutor/my-courses/:course_id/banner" do
    setup :register_and_log_in_lecturer

    test "should respond with 400 if the course id is invalid.", %{conn: conn} do
      conn
      |> get(~p"/tutor/my-courses/foo/banner")
      |> response(400)
    end

    test "should respond with 400 if the course cannot be found.", %{conn: conn} do
      conn
      |> get(~p"/tutor/my-courses/50000000/banner")
      |> response(400)
    end

    test "should respond with 400 if the lecturer is not assigned to the course.", %{conn: conn} do
      cr = course_fixture()

      conn
      |> get(~p"/tutor/my-courses/#{cr.id}/banner")
      |> response(400)
    end

    test "should respond with the course banner for the lecturer.", %{
      conn: conn,
      user: lecturer
    } do
      cr = course_fixture()
      {:ok, _} = Lukas.Learning.Course.Staff.add_lecturer_to_course(cr, lecturer)

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

      gotten =
        conn
        |> get(~p"/tutor/my-courses/#{cr.id}/banner")
        |> response(200)

      assert gotten == wanted
    end
  end

  describe "GET /home/courses/:course_id/banner" do
    setup :register_and_log_in_student

    test "should respond with 400 if the course id is invalid.", %{conn: conn} do
      conn
      |> get(~p"/home/courses/foo/banner")
      |> response(400)
    end

    test "should respond with 400 if the course cannot be found.", %{conn: conn} do
      conn
      |> get(~p"/home/courses/50000000/banner")
      |> response(400)
    end

    test "should respond with the course banner for the student.", %{
      conn: conn
    } do
      cr = course_fixture()

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

      gotten =
        conn
        |> get(~p"/home/courses/#{cr.id}/banner")
        |> response(200)

      assert gotten == wanted
    end
  end
end
