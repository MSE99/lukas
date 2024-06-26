defmodule LukasWeb.Router do
  use LukasWeb, :router

  import LukasWeb.UserAuth

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {LukasWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(:fetch_current_user)
    plug(:fetch_current_locale)
  end

  pipeline :api do
    plug(:accepts, ["json"])
    plug(:fetch_student_by_api_token)
  end

  scope "/", LukasWeb do
    pipe_through([:browser, :redirect_if_user_is_authenticated])

    live_session :public, on_mount: [{LukasWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/", Public.HomeLive
      live "/about-us", Public.AboutUsLive

      live "/courses", Public.CoursesLive, :index
      live "/courses/new", Public.CoursesLive, :new

      live "/courses/:id", Public.CourseLive
      live "/log_in", UserLoginLive
    end

    get "/courses/:id/banner", MediaController, :get_course_banner_for_visitor
  end

  scope "/media", LukasWeb do
    pipe_through [
      :fetch_session,
      :fetch_live_flash,
      :fetch_current_user,
      :require_authenticated_staff
    ]

    post "/", MediaController, :handle_upload
  end

  scope "/controls", LukasWeb do
    pipe_through([:browser, :require_authenticated_operator])

    live_session :controls, on_mount: [{LukasWeb.UserAuth, :ensure_authenticated_operator}] do
      live("/", Operators.HomeLive)

      live("/students", Operator.StudentsLive)
      live("/students/:id", Operator.StudentLive)

      live("/operators", Operator.OperatorsLive)

      live("/lecturers", Operator.LecturersLive)
      live("/lecturers/:id", Operator.LecturerLive)

      live("/invites", Operator.InvitesLive)

      live("/courses", Operator.AllCoursesLive, :index)
      live("/courses/new", Operator.AllCoursesLive, :new)
      live("/courses/:id/edit", Operator.AllCoursesLive, :edit)
      live("/courses/:id/settings", Operator.CourseSettingsLive)

      live("/courses/:id", Operator.CourseLive)
      live("/courses/:id/assign-lecturer", Operator.AssignLecturerLive, :add_lecturer)

      live("/courses/:id/lessons", Operator.CourseLessonsLive)

      live("/courses/:id/lessons/:lesson_id", Operator.LessonLive)
      live("/courses/:id/lessons/:lesson_id/new-topic", Operator.LessonLive, :new_topic)

      live("/courses/:id/enrollments", Operator.CourseEnrollmentsLive)

      live(
        "/courses/:id/lessons/:lesson_id/topics/:topic_id/edit-topic",
        Operator.LessonLive,
        :edit_topic
      )

      live("/tags", TagLive.Index, :index)
      live("/tags/new", TagLive.Index, :new)
      live("/tags/:id/edit", TagLive.Index, :edit)

      live("/tags/:id", TagLive.Show, :show)
      live("/tags/:id/show/edit", TagLive.Show, :edit)

      live("/stats", Operator.StatsLive)

      live("/cards", Operator.CardsLive)
    end

    get "/courses/:id/banner", MediaController, :get_course_banner
    get "/courses/:id/lessons/:lesson_id/image", MediaController, :get_lesson_image

    get "/courses/:id/lessons/:lesson_id/topics/:topic_id/media",
        MediaController,
        :get_topic_media
  end

  scope "/tutor", LukasWeb do
    pipe_through([:browser, :require_authenticated_lecturer])

    live_session :tutor, on_mount: [{LukasWeb.UserAuth, :ensure_authenticated_lecturer}] do
      live("/", Lecturer.HomeLive)
      live("/my-courses", Lecturer.CoursesLive, :index)
      live("/my-courses/new", Lecturer.CoursesLive, :new)
      live("/my-courses/:id/edit", Lecturer.CoursesLive, :edit)
      live("/my-courses/:id/settings", Lecturer.CourseSettingsLive, :edit)

      live("/my-courses/:id", Lecturer.CourseLive)

      live("/my-courses/:id/lessons", Lecturer.CourseLessonsLive)

      live("/my-courses/:id/lessons/:lesson_id", Lecturer.LessonLive)
      live("/my-courses/:id/lessons/:lesson_id/new-topic", Lecturer.LessonLive, :new_topic)

      live("/my-courses/:id/enrollments", Lecturer.CourseEnrollmentsLive)

      live(
        "/my-courses/:id/lessons/:lesson_id/topics/:topic_id/edit-topic",
        Lecturer.LessonLive,
        :edit_topic
      )
    end

    get "/my-courses/:id/banner", MediaController, :get_course_banner_for_lecturer

    get "/my-courses/:id/lessons/:lesson_id/image",
        MediaController,
        :get_lesson_image_for_lecturer

    get "/my-courses/:id/lessons/:lesson_id/topics/:topic_id/media",
        MediaController,
        :get_topic_media_for_lecturer
  end

  scope "/home", LukasWeb do
    pipe_through([:browser, :require_authenticated_student])

    live_session :students_home, on_mount: [{LukasWeb.UserAuth, :ensure_authenticated_student}] do
      live("/", Students.HomeLive)

      live("/courses", Students.CoursesLive)
      live("/courses/available", Students.AvailableCoursesLive)
      live("/courses/:id", Students.CourseLive)
      live("/courses/:id/lessons", Students.LessonsLive)
      live("/courses/:id/lessons/:lesson_id", Students.LessonsLive, :lesson)
      live("/courses/:id/lessons/:lesson_id/topics/:topic_id", Students.LessonsLive, :topic)

      live("/courses/:id/study", Students.StudyLive)

      live("/wallet", Students.WalletLive)
    end

    get "/courses/:id/banner", MediaController, :get_course_banner_for_student

    get "/courses/:id/lessons/:lesson_id/image",
        MediaController,
        :get_lesson_image_for_student

    get "/courses/:id/lessons/:lesson_id/topics/:topic_id/media",
        MediaController,
        :get_topic_media_for_student
  end

  ## Authentication routes

  scope "/", LukasWeb do
    pipe_through([:browser, :redirect_if_user_is_authenticated])

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{LukasWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live("/register/:code", Public.StaffRegistrationLive)

      live("/users/register", Public.StudentRegistrationLive, :new)
      live("/users/reset_password", UserForgotPasswordLive, :new)
      live("/users/reset_password/:token", UserResetPasswordLive, :edit)
    end

    post("/users/log_in", UserSessionController, :create)
  end

  scope "/", LukasWeb do
    pipe_through([:browser])
    get("/profile-image", UserController, :get_profile_image)
  end

  scope "/", LukasWeb do
    pipe_through([:browser, :require_authenticated_user])

    live_session :require_authenticated_user,
      on_mount: [{LukasWeb.UserAuth, :ensure_authenticated}] do
      live("/users/settings", UserSettingsLive, :edit)
      live("/users/settings/update-profile-image", UserSettingsLive, :update_profile_image)
      live("/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email)
    end
  end

  scope "/locale", LukasWeb do
    pipe_through :browser

    patch "/", LocaleController, :switch
  end

  scope "/", LukasWeb do
    pipe_through([:browser])

    delete("/users/log_out", UserSessionController, :delete)

    live_session :current_user,
      on_mount: [{LukasWeb.UserAuth, :mount_current_user}] do
      live("/users/confirm/:token", UserConfirmationLive, :edit)
      live("/users/confirm", UserConfirmationInstructionsLive, :new)
    end
  end

  # Students API
  scope "/api", LukasWeb do
    pipe_through [:api, :forbid_if_student_is_api_authenticated]

    post("/log_in", StudentTokenController, :create)
  end

  scope "/api", LukasWeb do
    pipe_through [:api, :require_api_authenticated_student]

    get("/whoami", StudentTokenController, :whoami)
    get("/socket-token", StudentTokenController, :get_socket_token)
  end
end
