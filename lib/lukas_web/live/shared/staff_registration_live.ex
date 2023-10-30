defmodule LukasWeb.Shared.StaffRegistrationLive do
  use LukasWeb, :live_view

  alias Lukas.Accounts

  def mount(%{"code" => code}, _, socket) do
    with inv when inv != nil <- Accounts.get_invite_by_code(code) do
      cs = Accounts.change_user_registration(%Accounts.User{}, %{})
      form = to_form(cs)
      {:ok, assign(socket, invite: inv, form: form)}
    else
      _ -> {:ok, redirect(socket, to: ~p"/")}
    end
  end

  def render(assigns) do
    ~H"""
    <span :if={@invite.kind == :lecturer}>
      Register lecturer
    </span>

    <span :if={@invite.kind == :operator}>
      Register operator
    </span>

    <.form for={@form} phx-change="validate" phx-submit="register">
      <.input type="text" label="Phone" field={@form[:phone_number]} />
      <.input type="password" label="Password" field={@form[:password]} />
      <.input type="text" label="Name" field={@form[:name]} />
      <.input type="email" label="Email" field={@form[:email]} />

      <.button>Register</.button>
    </.form>
    """
  end

  def handle_event("validate", %{"user" => params}, socket) do
    cs =
      Accounts.change_user_registration(%Accounts.User{}, params)
      |> Map.put(:action, :validate)

    form = to_form(cs)

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("register", %{"user" => params}, socket) do
    case register(params, socket.assigns.invite) do
      {:ok, _} ->
        {:noreply, redirect(socket, to: ~p"/log_in")}

      {:error, cs} ->
        {:noreply, assign(socket, form: to_form(cs))}
    end
  end

  defp register(params, invite) when invite.kind == :lecturer do
    Accounts.register_lecturer(invite, params)
  end

  defp register(params, invite) when invite.kind == :operator do
    Accounts.register_operator(invite, params)
  end
end
