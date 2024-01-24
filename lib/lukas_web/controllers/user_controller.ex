defmodule LukasWeb.UserController do
  use LukasWeb, :controller

  def get_profile_image(conn, _) do
    %{current_user: user} = conn.assigns

    image_path =
      Path.join([:code.priv_dir(:lukas), "static", "content", "users", user.profile_image])

    send_file(conn, 200, image_path)
  end
end
