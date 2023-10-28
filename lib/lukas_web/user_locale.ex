defmodule LukasWeb.UserLocale do
  def on_mount(:default, _params, session, socket) do
    Gettext.put_locale(LukasWeb.Gettext, session["locale"] || "en")
    {:cont, socket}
  end
end
