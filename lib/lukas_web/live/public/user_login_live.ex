defmodule LukasWeb.UserLoginLive do
  use LukasWeb, :live_view

  def mount(_params, _session, socket) do
    phone_number = live_flash(socket.assigns.flash, :phone_number)
    form = to_form(%{"phone_number" => phone_number}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header>
        <%= gettext("Login") %>

        <:subtitle>
          <%= gettext("Please enter your phone number and password") %>
        </:subtitle>
      </.header>

      <.form for={@form} class="mt-5" id="login_form" action={~p"/users/log_in"} phx-update="ignore">
        <div class="mb-5">
          <.input field={@form[:phone_number]} type="tel" label={gettext("Phone number")} required />
        </div>

        <div class="mb-5">
          <.input field={@form[:password]} type="password" label={gettext("Password")} required />
        </div>

        <.button phx-disable-with={gettext("Signing in...")} class="w-full">
          <%= gettext("Sign in") %>
        </.button>
      </.form>

      <div class="mt-5 font-bold underline">
        <.link href={~p"/users/register"}>
          <%= gettext("Register a new account") %>
        </.link>
      </div>
    </div>
    """
  end
end
