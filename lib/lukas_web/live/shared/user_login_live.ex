defmodule LukasWeb.UserLoginLive do
  use LukasWeb, :live_view

  def mount(_params, _session, socket) do
    phone_number = live_flash(socket.assigns.flash, :phone_number)
    form = to_form(%{"phone_number" => phone_number}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm px-5 lg:flex lg:flex-col justify-center">
      <h1 class="text-primary font-bold text-2xl mt-8 mb-16">Lukas</h1>

      <.form for={@form} id="login_form" action={~p"/users/log_in"} phx-update="ignore">
        <div class="mb-5">
          <.input field={@form[:phone_number]} type="tel" label="Phone number" required />
        </div>

        <div class="mb-5">
          <.input field={@form[:password]} type="password" label="Password" required />
        </div>

        <.button phx-disable-with="Signing in..." class="w-full">
          Sign in <span aria-hidden="true">→</span>
        </.button>
      </.form>

      <div class="mt-5 font-bold underline">
        <.link href={~p"/users/register"}>
          Register a new account
        </.link>
      </div>
    </div>
    """
  end
end
