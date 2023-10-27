defmodule LukasWeb.LocaleController do
  use LukasWeb, :controller

  def switch(conn, _) do
    locale = conn.assigns.locale
    next_locale = if locale == "en", do: "ar", else: "en"

    conn
    |> assign(:locale, next_locale)
    |> put_resp_cookie("locale", next_locale, max_age: 10 * 24 * 60 * 60)
    |> redirect(to: ~p"/")
  end
end
