defmodule Lukas.Accounts.Invite do
  use Ecto.Schema

  import Ecto.Changeset

  @invite_kinds [:operator, :lecturer]

  schema "invites" do
    field :kind, Ecto.Enum, values: @invite_kinds
    field :code, :string

    timestamps()
  end

  def changeset(invite, attrs) do
    invite
    |> cast(attrs, [:code, :kind])
    |> validate_inclusion(:kind, [:operator, :lecturer])
    |> validate_required([:code, :kind])
    |> validate_length(:code, is: 5)
    |> validate_format(:code, ~r/^[A-Za-z0-9]{5}$/)
    |> unique_constraint(:code)
  end
end
