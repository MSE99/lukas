defmodule Lukas.Accounts.Invite do
  use Ecto.Schema

  import Ecto.Changeset

  schema "invites" do
    field :code, :string

    timestamps()
  end

  def changeset(invite, attrs) do
    invite
    |> cast(attrs, [:code])
    |> validate_required([:code])
    |> validate_length(:code, is: 5)
    |> validate_format(:code, ~r/^[A-Za-z]{5}$/)
    |> unique_constraint(:code)
  end
end
