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

      live("/courses", Operator.AllCoursesLive, :index)
      live("/courses/new", Operator.AllCoursesLive, :new)
      live("/courses/:id", Operator.CourseLive)

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
      live("/", Lecturers.HomeLive)
    end
  end

  scope "/home", LukasWeb do
    pipe_through([:browser, :require_authenticated_student])

    live_session :students_home, on_mount: [{LukasWeb.UserAuth, :ensure_authenticated_student}] do
      live("/", Students.HomeLive)
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", LukasWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:lukas, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through(:browser)

      live_dashboard("/dashboard", metrics: LukasWeb.Telemetry)
      forward("/mailbox", Plug.Swoosh.MailboxPreview)
    end
  end

  ## Authentication routes

  scope "/", LukasWeb do
    pipe_through([:browser, :redirect_if_user_is_authenticated])

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{LukasWeb.UserAuth, :redirect_if_user_is_authenticated}] do
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
