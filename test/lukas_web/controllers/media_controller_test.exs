defmodule LukasWeb.MediaControllerTest do
  use LukasWeb.ConnCase, async: true

  import Lukas.AccountsFixtures
  import Lukas.LearningFixtures

  alias Lukas.Learning.Course.{Staff, Students}

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

  describe "GET /courses/:course_id/banner" do
    test "should respond with 400 if the course id is invalid.", %{conn: conn} do
      conn
      |> get(~p"/courses/foo/banner")
      |> response(400)
    end

    test "should respond with 400 if the course cannot be found.", %{conn: conn} do
      conn
      |> get(~p"/courses/50000000/banner")
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
        |> get(~p"/courses/#{cr.id}/banner")
        |> response(200)

      assert gotten == wanted
    end
  end

  describe "GET /controls/courses/:id/lessons/:lesson_id/image" do
    setup :register_and_log_in_user

    test "should respond with 400 if the course id is invalid.", %{conn: conn} do
      conn
      |> get(~p"/controls/courses/foo/lessons/foo/image")
      |> response(400)
    end

    test "should respond with 400 if the lesson id is invalid.", %{conn: conn} do
      cr = course_fixture()

      conn
      |> get(~p"/controls/courses/#{cr.id}/lessons/foo/image")
      |> response(400)
    end

    test "should respond with 400 if the lesson does not belong to the course or vice versa.", %{
      conn: conn
    } do
      cr = course_fixture()
      other_course = course_fixture()
      lesson = lesson_fixture(other_course)

      conn
      |> get(~p"/controls/courses/#{cr.id}/lessons/#{lesson.id}/image")
      |> response(400)
    end

    test "should respond with the image of the lesson.", %{
      conn: conn
    } do
      cr = course_fixture()
      lesson = lesson_fixture(cr)

      wanted = Lukas.Media.read_lesson_image!(lesson)

      gotten =
        conn
        |> get(~p"/controls/courses/#{cr.id}/lessons/#{lesson.id}/image")
        |> response(200)

      assert gotten == wanted
    end
  end

  describe "GET /tutor/my-courses/:id/lessons/:lesson_id/image" do
    setup :register_and_log_in_lecturer

    test "should respond with 400 if the course id is invalid.", %{conn: conn} do
      conn
      |> get(~p"/tutor/my-courses/foo/lessons/foo/image")
      |> response(400)
    end

    test "should respond with 400 if the lesson id is invalid.", %{conn: conn} do
      cr = course_fixture()

      conn
      |> get(~p"/tutor/my-courses/#{cr.id}/lessons/foo/image")
      |> response(400)
    end

    test "should respond with 400 if the lecturer is not assigned to the course.", %{
      conn: conn
    } do
      cr = course_fixture()
      lesson = lesson_fixture(cr)

      conn
      |> get(~p"/tutor/my-courses/#{cr.id}/lessons/#{lesson.id}/image")
      |> response(400)
    end

    test "should respond with 400 if the lesson does not belong to the course or vice versa.", %{
      conn: conn
    } do
      cr = course_fixture()
      other_course = course_fixture()
      lesson = lesson_fixture(other_course)

      conn
      |> get(~p"/tutor/my-courses/#{cr.id}/lessons/#{lesson.id}/image")
      |> response(400)
    end

    test "should respond with the image of the lesson.", %{
      conn: conn,
      user: lecturer
    } do
      cr = course_fixture()
      lesson = lesson_fixture(cr)

      {:ok, _} = Staff.add_lecturer_to_course(cr, lecturer)

      wanted = Lukas.Media.read_lesson_image!(lesson)

      gotten =
        conn
        |> get(~p"/tutor/my-courses/#{cr.id}/lessons/#{lesson.id}/image")
        |> response(200)

      assert gotten == wanted
    end
  end

  describe "GET /home/courses/:id/lessons/:lesson_id/image" do
    setup :register_and_log_in_student

    test "should respond with 400 if the course id is invalid.", %{conn: conn} do
      conn
      |> get(~p"/home/courses/foo/lessons/foo/image")
      |> response(400)
    end

    test "should respond with 400 if the lesson id is invalid.", %{conn: conn} do
      cr = course_fixture()

      conn
      |> get(~p"/home/courses/#{cr.id}/lessons/foo/image")
      |> response(400)
    end

    test "should respond with the image of the lesson.", %{
      conn: conn,
      user: student
    } do
      cr = course_fixture()
      lesson = lesson_fixture(cr)

      Lukas.Money.directly_deposit_to_student!(
        user_fixture(),
        student,
        5_000_000
      )

      {:ok, _} = Students.enroll_student(cr, student)

      wanted = Lukas.Media.read_lesson_image!(lesson)

      gotten =
        conn
        |> get(~p"/home/courses/#{cr.id}/lessons/#{lesson.id}/image")
        |> response(200)

      assert gotten == wanted
    end
  end

  describe "GET /controls/courses/:id/lessons/:lesson_id/topics/:topic_id/media" do
    setup :register_and_log_in_user

    test "should respond with 400 if the course id is invalid.", %{conn: conn} do
      lesson = lesson_fixture(course_fixture())
      topic = text_topic_fixture(lesson)

      conn
      |> get(~p"/controls/courses/foo/lessons/#{lesson.id}/topics/#{topic.id}/media")
      |> response(400)
    end

    test "should respond with 400 if the lesson id is invalid.", %{conn: conn} do
      course = course_fixture()
      topic = text_topic_fixture(lesson_fixture(course))

      conn
      |> get(~p"/controls/courses/#{course.id}/lessons/foo-bar-baz/topics/#{topic.id}/media")
      |> response(400)
    end

    test "should respond with 400 if the topic id is invalid.", %{conn: conn} do
      course = course_fixture()
      lesson = lesson_fixture(course)

      conn
      |> get(~p"/controls/courses/#{course.id}/lessons/#{lesson.id}/topics/foo-bar-baz/media")
      |> response(400)
    end

    test "should respond with 400 if the topic cannot be found using the ids.", %{conn: conn} do
      course = course_fixture()
      lesson = lesson_fixture(course)

      conn
      |> get(~p"/controls/courses/#{course.id}/lessons/#{lesson.id}/topics/404/media")
      |> response(400)
    end

    test "should send the topic media to the user.", %{conn: conn} do
      course = course_fixture()
      lesson = lesson_fixture(course)
      topic = text_topic_fixture(lesson)

      wanted =
        topic
        |> Lukas.Media.get_topic_media_filepath()
        |> File.read!()

      gotten =
        conn
        |> get(~p"/controls/courses/#{course.id}/lessons/#{lesson.id}/topics/#{topic.id}/media")
        |> response(200)

      assert gotten == wanted
    end
  end

  describe "GET /tutor/my-courses/:id/lessons/:lesson_id/topics/:topic_id/media" do
    setup :register_and_log_in_lecturer

    test "should respond with 400 if the course id is invalid.", %{conn: conn} do
      lesson = lesson_fixture(course_fixture())
      topic = text_topic_fixture(lesson)

      conn
      |> get(~p"/tutor/my-courses/foo/lessons/#{lesson.id}/topics/#{topic.id}/media")
      |> response(400)
    end

    test "should respond with 400 if the lesson id is invalid.", %{conn: conn} do
      course = course_fixture()
      topic = text_topic_fixture(lesson_fixture(course))

      conn
      |> get(~p"/tutor/my-courses/#{course.id}/lessons/foo-bar-baz/topics/#{topic.id}/media")
      |> response(400)
    end

    test "should respond with 400 if the topic id is invalid.", %{conn: conn} do
      course = course_fixture()
      lesson = lesson_fixture(course)

      conn
      |> get(~p"/tutor/my-courses/#{course.id}/lessons/#{lesson.id}/topics/foo-bar-baz/media")
      |> response(400)
    end

    test "should respond with 400 if the topic cannot be found using the ids.", %{conn: conn} do
      course = course_fixture()
      lesson = lesson_fixture(course)

      conn
      |> get(~p"/tutor/my-courses/#{course.id}/lessons/#{lesson.id}/topics/404/media")
      |> response(400)
    end

    test "should send the topic media to the user.", %{conn: conn, user: lecturer} do
      course = course_fixture()
      lesson = lesson_fixture(course)
      topic = text_topic_fixture(lesson)

      Staff.add_lecturer_to_course(course, lecturer)

      wanted =
        topic
        |> Lukas.Media.get_topic_media_filepath()
        |> File.read!()

      gotten =
        conn
        |> get(~p"/tutor/my-courses/#{course.id}/lessons/#{lesson.id}/topics/#{topic.id}/media")
        |> response(200)

      assert gotten == wanted
    end

    test "should respond with 400 if the lecturer is not assigned to the course.", %{conn: conn} do
      course = course_fixture()
      lesson = lesson_fixture(course)
      topic = text_topic_fixture(lesson)

      conn
      |> get(~p"/tutor/my-courses/#{course.id}/lessons/#{lesson.id}/topics/#{topic.id}/media")
      |> response(400)
    end
  end

  describe "GET /home/courses/:id/lessons/:lesson_id/topics/:topic_id/media" do
    setup :register_and_log_in_student

    test "should respond with 400 if the course id is invalid.", %{conn: conn} do
      lesson = lesson_fixture(course_fixture())
      topic = text_topic_fixture(lesson)

      conn
      |> get(~p"/home/courses/foo/lessons/#{lesson.id}/topics/#{topic.id}/media")
      |> response(400)
    end

    test "should respond with 400 if the lesson id is invalid.", %{conn: conn} do
      course = course_fixture()
      topic = text_topic_fixture(lesson_fixture(course))

      conn
      |> get(~p"/home/courses/#{course.id}/lessons/foo-bar-baz/topics/#{topic.id}/media")
      |> response(400)
    end

    test "should respond with 400 if the topic id is invalid.", %{conn: conn} do
      course = course_fixture()
      lesson = lesson_fixture(course)

      conn
      |> get(~p"/home/courses/#{course.id}/lessons/#{lesson.id}/topics/foo-bar-baz/media")
      |> response(400)
    end

    test "should send the topic media to the user.", %{conn: conn, user: student} do
      course = course_fixture()
      lesson = lesson_fixture(course)
      topic = text_topic_fixture(lesson)

      Lukas.Money.directly_deposit_to_student!(
        user_fixture(),
        student,
        5_000_000
      )

      {:ok, _} = Students.enroll_student(course, student)

      wanted =
        topic
        |> Lukas.Media.get_topic_media_filepath()
        |> File.read!()

      gotten =
        conn
        |> get(~p"/home/courses/#{course.id}/lessons/#{lesson.id}/topics/#{topic.id}/media")
        |> response(200)

      assert gotten == wanted
    end
  end
end
