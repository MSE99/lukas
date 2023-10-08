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
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", LukasWeb do
    pipe_through([:browser, :redirect_if_user_is_authenticated])

    get("/", PageController, :home)
  end

  scope "/controls", LukasWeb do
    pipe_through([:browser, :require_authenticated_operator])

    live_session :controls, on_mount: [{LukasWeb.UserAuth, :ensure_authenticated_operator}] do
      live("/", Operators.HomeLive)

      live("/students", Operator.StudentsLive)
      live("/lecturers", Operator.LecturersLive)

      live("/invites", Operator.InvitesLive)

      live("/courses", Operator.AllCoursesLive, :index)
      live("/courses/new", Operator.AllCoursesLive, :new)
      live("/courses/:id", Operator.CourseLive)
      live("/courses/:id/add-lecturer", Operator.CourseLive, :add_lecturer)
      live("/courses/:id/new-lesson", Operator.CourseLive, :new_lesson)
      live("/courses/:id/lessons/:lesson_id/edit-lesson", Operator.CourseLive, :edit_lesson)
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
    end
  end

  scope "/tutor", LukasWeb do
    pipe_through([:browser, :require_authenticated_lecturer])

    live_session :tutor, on_mount: [{LukasWeb.UserAuth, :ensure_authenticated_lecturer}] do
      live("/", Lecturer.HomeLive)
      live("/my-courses", Lecturer.CoursesLive, :index)
      live("/my-courses/new", Lecturer.CoursesLive, :new)

      live("/my-courses/:id", Lecturer.CourseLive)
      live("/my-courses/:id/new-lesson", Lecturer.CourseLive, :new_lesson)
      live("/my-courses/:id/lessons/:lesson_id/edit-lesson", Lecturer.CourseLive, :edit_lesson)
      live("/my-courses/:id/lessons/:lesson_id", Lecturer.LessonLive)
      live("/my-courses/:id/lessons/:lesson_id/new-topic", Lecturer.LessonLive, :new_topic)

      live("/my-courses/:id/enrollments", Lecturer.CourseEnrollmentsLive)

      live(
        "/my-courses/:id/lessons/:lesson_id/topics/:topic_id/edit-topic",
        Lecturer.LessonLive,
        :edit_topic
      )
    end
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
  end

  ## Authentication routes

  scope "/", LukasWeb do
    pipe_through([:browser, :redirect_if_user_is_authenticated])

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{LukasWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live("/register/:code", Shared.LecturerRegistrationLive)

      live("/users/register", UserRegistrationLive, :new)
      live("/users/log_in", UserLoginLive, :new)
      live("/users/reset_password", UserForgotPasswordLive, :new)
      live("/users/reset_password/:token", UserResetPasswordLive, :edit)
    end

    post("/users/log_in", UserSessionController, :create)
  end

  scope "/", LukasWeb do
    pipe_through([:browser, :require_authenticated_user])

    live_session :require_authenticated_user,
      on_mount: [{LukasWeb.UserAuth, :ensure_authenticated}] do
      live("/users/settings", UserSettingsLive, :edit)
      live("/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email)
    end
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
end
