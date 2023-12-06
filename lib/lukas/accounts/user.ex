defmodule Lukas.Accounts.User do
  use Ecto.Schema

  import Ecto.Changeset

  @user_kinds [:operator, :student, :lecturer]

  defguard must_be_lecturer(user) when is_struct(user, __MODULE__) and user.kind == :lecturer
  defguard must_be_student(user) when is_struct(user, __MODULE__) and user.kind == :student
  defguard must_be_operator(user) when is_struct(user, __MODULE__) and user.kind == :operator

  @derive {Jason.Encoder, except: [:password, :hashed_password, :__meta__]}
  schema "users" do
    field(:phone_number, :string)
    field(:email, :string)
    field(:password, :string, virtual: true, redact: true)
    field(:hashed_password, :string, redact: true)
    field(:confirmed_at, :naive_datetime)
    field(:kind, Ecto.Enum, values: @user_kinds)
    field(:name, :string)
    field(:profile_image, :string, default: "default-profile.png")
    field(:enabled, :boolean, default: true)

    timestamps()
  end

  def enable(user) do
    user
    |> cast(%{enabled: true}, [:enabled])
  end

  def disable(user) do
    user
    |> cast(%{enabled: false}, [:enabled])
  end

  def lecturer_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :password, :phone_number, :kind, :name])
    |> validate_inclusion(:kind, [:lecturer])
    |> validate_user_props(opts)
  end

  def student_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :password, :phone_number, :kind, :name])
    |> validate_inclusion(:kind, [:student])
    |> validate_user_props(opts)
  end

  def operator_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :password, :phone_number, :kind, :name])
    |> validate_inclusion(:kind, [:operator])
    |> validate_user_props(opts)
  end

  defp validate_user_props(changeset, opts) do
    changeset
    |> validate_phone_number()
    |> validate_email(opts)
    |> validate_password(opts)
    |> validate_name()
  end

  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :password, :phone_number, :kind, :name])
    |> validate_phone_number()
    |> validate_email(opts)
    |> validate_password(opts)
    |> validate_kinds()
    |> validate_name()
  end

  def profile_image_changeset(user, attrs) do
    user
    |> cast(attrs, [:profile_image])
    |> validate_required([:profile_image])
    |> unique_constraint([:profile_image])
  end

  defp validate_name(changeset) do
    changeset
    |> validate_required(:name)
    |> validate_length(:name, min: 3, max: 100)
  end

  defp validate_kinds(changeset) do
    changeset
    |> validate_required(:kind)
    |> validate_inclusion(:kind, @user_kinds)
  end

  defp validate_phone_number(changeset) do
    changeset
    |> validate_required([:phone_number])
    |> unique_constraint(:phone_number)
  end

  defp validate_email(changeset, opts) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> maybe_validate_unique_email(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72)
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      |> validate_length(:password, max: 72, count: :bytes)
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  defp maybe_validate_unique_email(changeset, opts) do
    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, Lukas.Repo)
      |> unique_constraint(:email)
    else
      changeset
    end
  end

  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  def confirm_changeset(user) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  def valid_password?(%Lukas.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  def validate_current_password(changeset, password) do
    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end

  def is_operator?(%__MODULE__{kind: :operator}), do: true
  def is_operator?(_), do: false

  def is_student?(%__MODULE__{kind: :student}), do: true
  def is_student?(_), do: false

  def is_lecturer?(%__MODULE__{kind: :lecturer}), do: true
  def is_lecturer?(_), do: false
end
