defmodule LukasWeb.UserSettingsLive do
  use LukasWeb, :live_view

  alias Lukas.Accounts

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_user, token) do
        :ok ->
          put_flash(socket, :info, gettext("Email changed successfully."))

        :error ->
          put_flash(socket, :error, gettext("Email change link is invalid or it has expired."))
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    email_changeset = Accounts.change_user_email(user)
    password_changeset = Accounts.change_user_password(user)

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:current_phone_number, user.phone_number)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)
      |> allow_upload(:profile_image, accept: ~w(.jpg .png .jpeg))

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <.header class="text-center mb-10 mt-12">
      <%= gettext("Account Settings") %>
    </.header>

    <div class="space-y-12 divide-y">
      <div class="flex flex-col justify-center items-center">
        <img
          src={~p"/profile-image"}
          width={250}
          height={250}
          class="rounded-full border-8 border-primary-opaque mb-7 w-[250px] h-[250px]"
          phx-click={show_modal("update-profile-image-modal")}
        />
      </div>

      <div>
        <.form
          for={@email_form}
          id="email_form"
          phx-submit="update_email"
          phx-change="validate_email"
          class="flex flex-col gap-3 mt-5"
        >
          <.input field={@email_form[:email]} type="email" label={gettext("Email")} required />
          <.input
            field={@email_form[:current_password]}
            name="current_password"
            id="current_password_for_email"
            type="password"
            label={gettext("Current password")}
            value={@email_form_current_password}
            required
          />
          <.button phx-disable-with={gettext("Changing...")} class="bg-primary self-end">
            <%= gettext("Change Email") %>
          </.button>
        </.form>
      </div>
      <div>
        <.form
          for={@password_form}
          id="password_form"
          action={~p"/users/log_in?_action=password_updated"}
          method="post"
          phx-change="validate_password"
          phx-submit="update_password"
          phx-trigger-action={@trigger_submit}
          class="flex flex-col gap-3 mb-3"
        >
          <.input
            field={@password_form[:phone_number]}
            type="hidden"
            id="hidden_user_phone_number"
            value={@current_phone_number}
          />

          <.input
            field={@password_form[:email]}
            type="hidden"
            id="hidden_user_email"
            value={@current_email}
          />
          <.input
            field={@password_form[:password]}
            type="password"
            label={gettext("New password")}
            required
          />
          <.input
            field={@password_form[:password_confirmation]}
            type="password"
            label={gettext("Confirm new password")}
          />
          <.input
            field={@password_form[:current_password]}
            name="current_password"
            type="password"
            label={gettext("Current password")}
            id="current_password_for_password"
            value={@current_password}
            required
          />
          <.button phx-disable-with={gettext("Changing...")} class="bg-primary self-end">
            <%= gettext("Change Password") %>
          </.button>
        </.form>
      </div>
    </div>

    <.modal id="update-profile-image-modal">
      <div
        id="image-cropper"
        phx-update="ignore"
        phx-hook="ImageCropper"
        data-name="profile_image"
        class="w-full"
      >
        <input type="file" id="image-cropper-input" accept=".jpg,.jpeg,.png" />
      </div>

      <.button class="mt-5" id="crop-button"><%= gettext("Crop") %></.button>

      <form
        id="profile-image-form"
        phx-change="validate-profile-image"
        phx-submit="update-profile-image"
        class="flex flex-col gap-3"
      >
        <.live_file_input upload={@uploads.profile_image} class="hidden live-file-input" />
        <.button :if={length(@uploads.profile_image.entries) > 0} class="mt-5" id="upload-button">
          <%= gettext("Save") %>
        </.button>

        <%= for entry <- @uploads.profile_image.entries do %>
          <progress value={entry.progress} max="100">
            <%= entry.progress %>%
          </progress>

          <.live_img_preview entry={entry} width={100} height={100} />

          <%= for err <- upload_errors(@uploads.profile_image, entry) do %>
            <p class="alert alert-danger"><%= error_to_string(err) %></p>
          <% end %>
        <% end %>
      </form>
    </.modal>
    """
  end

  def error_to_string(:too_large), do: gettext("Too large")
  def error_to_string(:not_accepted), do: gettext("You have selected an unacceptable file type")

  defp ext(upload_entry) do
    [ext | _] = MIME.extensions(upload_entry.client_type)
    ext
  end

  def handle_event("validate-profile-image", _, socket) do
    {:noreply, socket}
  end

  def handle_event("update-profile-image", _, socket) do
    consume_uploaded_entries(socket, :profile_image, fn %{path: path}, entry ->
      filename = "#{entry.uuid}.#{ext(entry)}"
      dist = Path.join([:code.priv_dir(:lukas), "static", "content", "users", filename])

      {:ok, next_user} =
        Accounts.update_user_profile_image(
          socket.assigns.current_user,
          %{profile_image: filename},
          fn -> File.cp!(path, dist) end
        )

      send(self(), {:user_updated, next_user})

      {:ok, dist}
    end)

    {:noreply, socket}
  end

  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    email_form =
      socket.assigns.current_user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_user_update_email_instructions(
          applied_user,
          user.email,
          &url(~p"/users/settings/confirm_email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    password_form =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        password_form =
          user
          |> Accounts.change_user_password(user_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end

  def handle_info({:user_updated, next_user}, socket) do
    {:noreply, assign(socket, current_user: next_user)}
  end
end
