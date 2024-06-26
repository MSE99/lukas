defmodule Lukas.Accounts do
  import Ecto.Query, warn: false

  alias Lukas.Repo
  alias Lukas.Accounts.{User, UserToken, UserNotifier, Invite, Query}

  alias Ecto.Multi

  # Operators
  def get_operator(id) when is_integer(id) do
    id
    |> Query.operator_by_id()
    |> Repo.one()
  end

  def list_operators(opts \\ []) do
    opts
    |> Query.operators()
    |> Repo.all()
  end

  def watch_operators() do
    Phoenix.PubSub.subscribe(Lukas.PubSub, "operators")
  end

  def register_operator(
        %Invite{kind: :operator} = invite,
        attrs,
        get_image_path \\ fn -> "default-profile.png" end
      ) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:user, User.operator_changeset(%User{kind: :operator}, attrs))
    |> Ecto.Multi.delete(:invite, invite)
    |> Ecto.Multi.run(:user_with_image, fn _, %{user: user} ->
      updated =
        user
        |> User.profile_image_changeset(%{profile_image: get_image_path.()})
        |> Repo.update!()

      {:ok, updated}
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{user_with_image: user, invite: invite}} ->
        emit_operator_registered(user)
        emit_invite_deleted(invite)
        {:ok, user}

      {:error, :user, changeset, _} ->
        {:error, changeset}
    end
  end

  defp emit_operator_registered(operator) do
    Phoenix.PubSub.broadcast(
      Lukas.PubSub,
      "operators",
      {:operators, :operator_registered, operator}
    )

    operator
  end

  # Students
  def register_student(attrs) do
    %User{kind: :student}
    |> User.student_changeset(attrs)
    |> Repo.insert()
    |> maybe_emit_student_registered()
  end

  defp maybe_emit_student_registered({:ok, user} = res) when user.kind == :student do
    Phoenix.PubSub.broadcast(Lukas.PubSub, "students", {:students, :student_registered, user})
    res
  end

  defp maybe_emit_student_registered(res), do: res

  def watch_students() do
    Phoenix.PubSub.subscribe(Lukas.PubSub, "students")
  end

  def watch_student(%User{kind: :student, id: id}) do
    Phoenix.PubSub.subscribe(Lukas.PubSub, "students/#{id}")
  end

  def list_students(opts \\ []) do
    opts
    |> Query.students()
    |> Repo.all()
  end

  # Lecturers
  def register_lecturer(
        %Invite{kind: :lecturer} = invite,
        attrs,
        get_image_path \\ fn -> "default-profile.png" end
      ) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(
      :user,
      User.lecturer_changeset(%User{kind: :lecturer, enabled: false}, attrs)
    )
    |> Ecto.Multi.delete(:invite, invite)
    |> Ecto.Multi.run(:user_with_image, fn _, %{user: user} ->
      updated =
        user
        |> User.profile_image_changeset(%{profile_image: get_image_path.()})
        |> Repo.update!()

      {:ok, updated}
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{user_with_image: user, invite: invite}} ->
        emit_lecturer_registered(user)
        emit_invite_deleted(invite)
        {:ok, user}

      {:error, :user, changeset, _} ->
        {:error, changeset}
    end
  end

  def emit_lecturer_registered(lect) do
    Phoenix.PubSub.broadcast(Lukas.PubSub, "lecturers", {:lecturers, :lecturer_registered, lect})
  end

  def watch_lecturers() do
    Phoenix.PubSub.subscribe(Lukas.PubSub, "lecturers")
  end

  def watch_lecturer(%User{kind: :lecturer} = lect) do
    Phoenix.PubSub.subscribe(Lukas.PubSub, "lecturers/#{lect.id}")
  end

  def list_lecturers(opts \\ []) do
    opts
    |> Query.lecturers()
    |> Repo.all()
  end

  def get_lecturer(lecturer_id) when is_integer(lecturer_id) do
    Repo.get_by(User, kind: :lecturer, id: lecturer_id)
  end

  def get_lecturer!(lecturer_id) when is_integer(lecturer_id) do
    Repo.get_by!(User, kind: :lecturer, id: lecturer_id)
  end

  # Generic
  def enable_user(%User{} = u) do
    u
    |> User.enable()
    |> Repo.update()
    |> maybe_emit_user_updated()
  end

  def disable_user(%User{} = u) do
    u
    |> User.disable()
    |> Repo.update()
    |> maybe_emit_user_updated()
  end

  defp maybe_emit_user_updated({:ok, user} = res) do
    case user.kind do
      :operator ->
        Phoenix.PubSub.broadcast(Lukas.PubSub, "operators", {:operators, :operator_updated, user})

      :lecturer ->
        Phoenix.PubSub.broadcast(Lukas.PubSub, "lecturers", {:lecturers, :lecturer_updated, user})

        Phoenix.PubSub.broadcast(
          Lukas.PubSub,
          "lecturers/#{user.id}",
          {:lecturer, user.id, :lecturer_updated, user}
        )

      :student ->
        Phoenix.PubSub.broadcast(Lukas.PubSub, "students", {:students, :student_updated, user})

        Phoenix.PubSub.broadcast(
          Lukas.PubSub,
          "students/#{user.id}",
          {:student, user.id, :student_updated, user}
        )
    end

    res
  end

  defp maybe_emit_user_updated(res), do: res

  def get_user_by_phone_number_and_password(phone_number, password)
      when is_binary(phone_number) and is_binary(password) do
    user = get_user_by_phone_number(phone_number)
    if User.valid_password?(user, password), do: user
  end

  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = get_user_by_email(email)
    if User.valid_password?(user, password), do: user
  end

  def get_user_by_phone_number(phone_number) when is_binary(phone_number) do
    phone_number
    |> Query.user_by_phone_number_and_enabled()
    |> Repo.one()
  end

  def get_user_by_email(email) when is_binary(email) do
    email
    |> Query.user_by_email_and_enabled()
    |> Repo.one()
  end

  def get_student(id) when is_integer(id) do
    id
    |> Query.student_by_id()
    |> Repo.one()
  end

  def get_student!(id) when is_integer(id) do
    id
    |> Query.student_by_id()
    |> Repo.one!()
  end

  def get_user!(id), do: Repo.get!(User, id)

  def get_user(id), do: Repo.get(User, id)

  # Students API
  def create_student_api_token(%User{kind: :student} = student) do
    {serialized_token, token} = UserToken.build_email_token(student, "api-token")
    Repo.insert!(token)
    serialized_token
  end

  def fetch_student_by_api_token(token) when is_binary(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "api-token"),
         %User{kind: :student} = user <- Repo.one(query) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  # Invites
  def list_invites() do
    Repo.all(Invite)
  end

  def delete_invite!(id) when is_integer(id) do
    Repo.get!(Invite, id)
    |> Repo.delete!()
    |> emit_invite_deleted()
  end

  def get_invite_by_code(code) when is_binary(code) do
    Repo.get_by(Invite, code: code)
  end

  def generate_lecturer_invite!() do
    Invite.changeset(%Invite{kind: :lecturer}, %{"code" => gen_code()})
    |> Repo.insert!()
    |> emit_invite_created()
  end

  def generate_operator_invite!() do
    Invite.changeset(%Invite{kind: :operator}, %{"code" => gen_code()})
    |> Repo.insert!()
    |> emit_invite_created()
  end

  def gen_code() do
    :crypto.strong_rand_bytes(5)
    |> Base.encode16()
    |> String.slice(0..4)
  end

  def watch_invites() do
    Phoenix.PubSub.subscribe(Lukas.PubSub, "invites")
  end

  defp emit_invite_created(invite) do
    Phoenix.PubSub.broadcast(Lukas.PubSub, "invites", {:invites, :invite_created, invite})
    invite
  end

  defp emit_invite_deleted(invite) do
    Phoenix.PubSub.broadcast(Lukas.PubSub, "invites", {:invites, :invite_deleted, invite})
    invite
  end

  ## User registration
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false, validate_email: false)
  end

  ## Settings

  def update_user_profile_image(user, attrs, side_effect \\ fn -> nil end) do
    Multi.new()
    |> Multi.update(:user, User.profile_image_changeset(user, attrs))
    |> Multi.run(:side_effect, fn _, _ ->
      side_effect.()
      {:ok, nil}
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, _, err, _} -> {:error, err}
    end
  end

  def change_user_profile_image(user, attrs \\ %{}) do
    User.profile_image_changeset(user, attrs)
  end

  def change_user_email(user, attrs \\ %{}) do
    User.email_changeset(user, attrs, validate_email: false)
  end

  def apply_user_email(user, password, attrs) do
    user
    |> User.email_changeset(attrs)
    |> User.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  def update_user_email(user, token) do
    context = "change:#{user.email}"

    with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
         %UserToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(user_email_multi(user, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp user_email_multi(user, email, context) do
    changeset =
      user
      |> User.email_changeset(%{email: email})
      |> User.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, [context]))
  end

  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  def deliver_user_confirmation_instructions(%User{} = user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
      Repo.insert!(user_token)
      UserNotifier.deliver_confirmation_instructions(user, confirmation_url_fun.(encoded_token))
    end
  end

  def confirm_user(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, %{user: user}} <- Repo.transaction(confirm_user_multi(user)) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  defp confirm_user_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user))
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, ["confirm"]))
  end

  ## Reset password

  def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    UserNotifier.deliver_reset_password_instructions(user, reset_password_url_fun.(encoded_token))
  end

  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  def reset_user_password(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end
end
