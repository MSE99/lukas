defmodule Lukas.Money.TxLog do
  use Ecto.Schema

  import Ecto.Changeset

  schema "transaction_logs" do
    field(:count, :integer)
    field(:amount, :float)

    belongs_to(:student, Lukas.Accounts.User)

    timestamps()
  end

  def changeset(log, attrs \\ %{}) do
    log
    |> cast(attrs, [:count, :amount, :student_id])
    |> validate_count()
    |> validate_amount()
    |> validate_student_id()
    |> unique_constraint([:count, :student_id])
  end

  defp validate_count(changeset) do
    changeset
    |> validate_required(:count)
    |> validate_number(:count, greater_than_or_equal_to: 0)
  end

  defp validate_amount(changeset) do
    changeset
    |> validate_required(:amount)
    |> validate_number(:amount, greater_than_or_equal_to: 0)
  end

  defp validate_student_id(changeset) do
    changeset
    |> validate_required(:student_id)
  end
end
