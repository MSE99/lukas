defmodule LukasWeb.UserController do
  use LukasWeb, :controller

  alias Lukas.Accounts

  def get_profile_image(conn, %{"user_id" => raw_user_id}) do
    IO.inspect("HIT HIT HIT HIT")

    with {user_id, _} <- Integer.parse(raw_user_id),
         user when user != nil <- Accounts.get_user(user_id) do
      image_path =
        Path.join([:code.priv_dir(:lukas), "static", "content", "users", user.profile_image])

      send_file(conn, 200, image_path)
    else
      _ -> send_resp(conn, 400, "Invalid user id or user with the given id cannot be found")
    end
  end

  def get_profile_image(conn, _) do
    %{current_user: user} = conn.assigns

    image_path =
      Path.join([:code.priv_dir(:lukas), "static", "content", "users", user.profile_image])

    send_file(conn, 200, image_path)
  end
end
