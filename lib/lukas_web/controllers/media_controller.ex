defmodule LukasWeb.MediaController do
  use LukasWeb, :controller

  alias Lukas.Learning

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

  def get_course_banner_for_student(conn, params) do
    get_course_banner(conn, params)
  end

  def get_course_banner(conn, %{"id" => raw_course_id}) do
    with {course_id, _} <- Integer.parse(raw_course_id),
         course when course != nil <- Learning.get_course(course_id) do
      banner_image =
        Path.join([
          :code.priv_dir(:lukas),
          "static",
          "content",
          "courses",
          "images",
          course.banner_image
        ])
        |> File.read!()

      send_resp(conn, 200, banner_image)
    else
      _ -> send_resp(conn, 400, "invalid course id")
    end
  end

  def get_course_banner_for_lecturer(conn, %{"id" => raw_course_id}) do
    with {course_id, _} <- Integer.parse(raw_course_id),
         {course, _} when course != nil <-
           Learning.get_course_and_tags_for_lecturer(course_id, conn.assigns.current_user.id) do
      banner_image =
        Path.join([
          :code.priv_dir(:lukas),
          "static",
          "content",
          "courses",
          "images",
          course.banner_image
        ])
        |> File.read!()

      send_resp(conn, 200, banner_image)
    else
      _ -> send_resp(conn, 400, "invalid course id")
    end
  end
end
