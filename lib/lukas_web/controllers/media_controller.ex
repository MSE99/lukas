defmodule LukasWeb.MediaController do
  use LukasWeb, :controller

  alias Lukas.{Learning, Media}
  alias Lukas.Learning.Course.{Content, Staff}

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

  def get_course_banner_for_visitor(conn, params) do
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

  def get_lesson_image(conn, %{"id" => raw_course_id, "lesson_id" => raw_lesson_id}) do
    with {course_id, _} <- Integer.parse(raw_course_id),
         {lesson_id, _} <- Integer.parse(raw_lesson_id),
         lesson when lesson != nil <- Content.get_lesson(course_id, lesson_id) do
      path = Media.get_lesson_image_filepath(lesson)
      send_file(conn, 200, path)
    else
      _ -> send_resp(conn, 400, "invalid course id")
    end
  end

  def get_lesson_image_for_lecturer(conn, %{"id" => raw_course_id, "lesson_id" => raw_lesson_id}) do
    with {course_id, _} <- Integer.parse(raw_course_id),
         {lesson_id, _} <- Integer.parse(raw_lesson_id),
         lesson when lesson != nil <- Content.get_lesson(course_id, lesson_id),
         is_assigned when is_assigned == true <-
           Staff.is_lecturer_assigned_to_course?(course_id, conn.assigns.current_user.id) do
      path = Media.get_lesson_image_filepath(lesson)
      send_file(conn, 200, path)
    else
      _ -> send_resp(conn, 400, "invalid course id")
    end
  end
end
