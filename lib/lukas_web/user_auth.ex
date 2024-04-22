defmodule LukasWeb.UserAuth do
  use LukasWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  alias Lukas.Accounts

  @max_age 60 * 60 * 24 * 60
  @remember_me_cookie "_lukas_web_user_remember_me"
  @remember_me_options [sign: true, max_age: @max_age, same_site: "Lax"]

  def log_in_user(conn, user, params \\ %{}) do
    token = Accounts.generate_user_session_token(user)
    user_return_to = get_session(conn, :user_return_to)

    conn
    |> renew_session()
    |> put_token_in_session(token)
    |> maybe_write_remember_me_cookie(token, params)
    |> redirect(to: user_return_to || signed_in_path(conn, user))
  end

  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
    put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
  end

  defp maybe_write_remember_me_cookie(conn, _token, _params) do
    conn
  end

  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  def log_out_user(conn) do
    user_token = get_session(conn, :user_token)
    user_token && Accounts.delete_user_session_token(user_token)

    if live_socket_id = get_session(conn, :live_socket_id) do
      LukasWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session()
    |> delete_resp_cookie(@remember_me_cookie)
    |> redirect(to: ~p"/")
  end

  def fetch_current_user(conn, _opts) do
    {user_token, conn} = ensure_user_token(conn)
    user = user_token && Accounts.get_user_by_session_token(user_token)
    assign(conn, :current_user, user)
  end

  def fetch_student_by_api_token(conn, _opts) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, user} <- Accounts.fetch_student_by_api_token(token) do
      assign(conn, :current_user, user)
    else
      _ -> assign(conn, :current_user, nil)
    end
  end

  def require_api_authenticated_student(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> send_resp(401, "Unauthorized")
      |> halt()
    end
  end

  def forbid_if_student_is_api_authenticated(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
      |> send_resp(403, "Forbidden")
      |> halt()
    else
      conn
    end
  end

  def fetch_current_locale(conn, _opts) do
    if conn.cookies["locale"] in ["ar", "en"] do
      locale = conn.cookies["locale"]
      Gettext.put_locale(LukasWeb.Gettext, locale)

      conn
      |> assign(:locale, locale)
      |> put_session(:locale, locale)
    else
      locale = Gettext.get_locale(LukasWeb.Gettext)

      conn
      |> assign(:locale, locale)
      |> put_resp_cookie("locale", locale, max_age: 10 * 24 * 60 * 60)
      |> put_session(:locale, locale)
    end
  end

  defp ensure_user_token(conn) do
    if token = get_session(conn, :user_token) do
      {token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if token = conn.cookies[@remember_me_cookie] do
        {token, put_token_in_session(conn, token)}
      else
        {nil, conn}
      end
    end
  end

  def on_mount(:mount_current_user, _params, session, socket) do
    {:cont, mount_current_user(socket, session)}
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    socket = mount_current_user(socket, session)

    if socket.assigns.current_user do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "You must log in to access this page.")
        |> Phoenix.LiveView.redirect(to: ~p"/log_in")

      {:halt, socket}
    end
  end

  def on_mount(:ensure_authenticated_operator, _params, session, socket) do
    socket = mount_current_user(socket, session)

    if Accounts.User.is_operator?(socket.assigns.current_user) do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "You must log in to access this page.")
        |> Phoenix.LiveView.redirect(to: ~p"/log_in")

      {:halt, socket}
    end
  end

  def on_mount(:ensure_authenticated_lecturer, _params, session, socket) do
    socket = mount_current_user(socket, session)

    if Accounts.User.is_lecturer?(socket.assigns.current_user) do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "You must log in to access this page.")
        |> Phoenix.LiveView.redirect(to: ~p"/log_in")

      {:halt, socket}
    end
  end

  def on_mount(:ensure_authenticated_student, _params, session, socket) do
    socket = mount_current_user(socket, session)

    if Accounts.User.is_student?(socket.assigns.current_user) do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "You must log in to access this page.")
        |> Phoenix.LiveView.redirect(to: ~p"/log_in")

      {:halt, socket}
    end
  end

  def on_mount(:redirect_if_user_is_authenticated, _params, session, socket) do
    socket = mount_current_user(socket, session)

    if socket.assigns.current_user do
      {:halt,
       Phoenix.LiveView.redirect(socket, to: signed_in_path(socket, socket.assigns.current_user))}
    else
      {:cont, socket}
    end
  end

  defp mount_current_user(socket, session) do
    Phoenix.Component.assign_new(socket, :current_user, fn ->
      if user_token = session["user_token"] do
        Accounts.get_user_by_session_token(user_token)
      end
    end)
  end

  @doc """
  Used for routes that require the user to not be authenticated.
  """
  def redirect_if_user_is_authenticated(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
      |> redirect(to: signed_in_path(conn, conn.assigns.current_user))
      |> halt()
    else
      conn
    end
  end

  @doc """
  Used for routes that require the user to be authenticated.

  If you want to enforce the user email is confirmed before
  they use the application at all, here would be a good place.
  """
  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> maybe_store_return_to()
      |> redirect(to: ~p"/log_in")
      |> halt()
    end
  end

  def require_authenticated_operator(conn, _opts) do
    if Accounts.User.is_operator?(conn.assigns[:current_user]) do
      conn
    else
      conn
      |> put_flash(:error, "Unauthorized.")
      |> maybe_store_return_to()
      |> redirect(to: ~p"/log_in")
      |> halt()
    end
  end

  def require_authenticated_lecturer(conn, _opts) do
    if Accounts.User.is_lecturer?(conn.assigns[:current_user]) do
      conn
    else
      conn
      |> put_flash(:error, "Unauthorized.")
      |> maybe_store_return_to()
      |> redirect(to: ~p"/log_in")
      |> halt()
    end
  end

  def require_authenticated_staff(conn, _opts) do
    current_user = conn.assigns[:current_user]

    if Accounts.User.is_lecturer?(current_user) || Accounts.User.is_operator?(current_user) do
      conn
    else
      conn
      |> put_flash(:error, "Unauthorized.")
      |> maybe_store_return_to()
      |> redirect(to: ~p"/log_in")
      |> halt()
    end
  end

  def require_authenticated_student(conn, _opts) do
    if Accounts.User.is_student?(conn.assigns[:current_user]) do
      conn
    else
      conn
      |> put_flash(:error, "Unauthorized.")
      |> maybe_store_return_to()
      |> redirect(to: ~p"/log_in")
      |> halt()
    end
  end

  defp put_token_in_session(conn, token) do
    conn
    |> put_session(:user_token, token)
    |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :user_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn

  defp signed_in_path(_, user) when user.kind == :operator do
    ~p"/controls"
  end

  defp signed_in_path(_, user) when user.kind == :student do
    ~p"/home"
  end

  defp signed_in_path(_, user) when user.kind == :lecturer do
    ~p"/tutor"
  end

  defp signed_in_path(_, _), do: ~p"/"
end
