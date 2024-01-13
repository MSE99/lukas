defmodule LukasWeb.MediaController do
  use LukasWeb, :controller

  def handle_upload(conn, %{"file" => file}) do
    filename = "#{Path.basename(file.path)}.#{ext(file)}"
    dest = Path.join([:code.priv_dir(:lukas), "static", "images", filename])

    File.cp!(file.path, dest)

    send_resp(conn, 200, %{"location" => "/images/#{filename}"} |> Jason.encode!())
  end

  defp ext(upload_entry) do
    [ext | _] = MIME.extensions(upload_entry.content_type)
    ext
  end
end
