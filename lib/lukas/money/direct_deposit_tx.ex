defmodule Lukas.Money.DirectDepositTx do
  use Ecto.Schema

  import Ecto.Changeset

  schema "direct_deposit_tx" do
    field(:kind, Ecto.Enum, values: [:direct])
    field(:amount, :float)

    belongs_to(:student, Lukas.Accounts.User)
    belongs_to(:clerk, Lukas.Accounts.User)

    timestamps()
  end

  def changeset(tx, attrs) do
    tx
    |> cast(attrs, [:kind, :amount, :student_id, :clerk_id])
    |> validate_required([:kind, :amount, :student_id, :clerk_id])
    |> validate_inclusion(:kind, [:direct])
    |> validate_number(:amount, greater_than_or_equal_to: 0)
  end
end
