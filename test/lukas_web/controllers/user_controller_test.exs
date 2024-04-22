defmodule LukasWeb.UserControllerTest do
  use LukasWeb.ConnCase, async: true

  import Lukas.AccountsFixtures

  def get_default_profile_image() do
    Path.join([:code.priv_dir(:lukas), "static", "content", "users", "default-profile.png"])
    |> File.read!()
  end

  test "should respond with the default profile image for students.", ctx do
    %{conn: conn} = register_and_log_in_student(ctx)

    default_profile_image =
      Path.join([:code.priv_dir(:lukas), "static", "content", "users", "default-profile.png"])
      |> File.read!()

    gotten =
      conn
      |> get(~p"/profile-image")
      |> response(200)

    assert gotten == default_profile_image
  end

  test "should respond with the default profile image for lecturers.", ctx do
    %{conn: conn} = register_and_log_in_lecturer(ctx)

    default_profile_image =
      Path.join([:code.priv_dir(:lukas), "static", "content", "users", "default-profile.png"])
      |> File.read!()

    gotten =
      conn
      |> get(~p"/profile-image")
      |> response(200)

    assert gotten == default_profile_image
  end

  test "should respond with the default profile image for operators.", ctx do
    %{conn: conn} = register_and_log_in_user(ctx)

    default_profile_image =
      Path.join([:code.priv_dir(:lukas), "static", "content", "users", "default-profile.png"])
      |> File.read!()

    gotten =
      conn
      |> get(~p"/profile-image")
      |> response(200)

    assert gotten == default_profile_image
  end

  describe "GET /profile-image?user_id" do
    setup :register_and_log_in_user

    test "should respond with 400 if the user id is invalid.", %{conn: conn} do
      conn
      |> get(~p"/profile-image?user_id=foo")
      |> response(400)
    end

    test "should respond with 400 if the user cannot be found.", %{conn: conn} do
      conn
      |> get(~p"/profile-image?user_id=5000000")
      |> response(400)
    end

    test "should respond with the profile image of the user.", %{conn: conn} do
      student = student_fixture()
      image = get_default_profile_image()

      gotten_image =
        conn
        |> get(~p"/profile-image?user_id=#{student.id}")
        |> response(200)

      assert gotten_image == image
    end
  end
end
