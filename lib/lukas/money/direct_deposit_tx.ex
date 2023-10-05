defmodule Lukas.Money.DirectDepositTx do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  schema "direct_deposits_txs" do
    field(:amount, :float)

    belongs_to(:student, Lukas.Accounts.User)
    belongs_to(:clerk, Lukas.Accounts.User)

    timestamps()
  end

  def new(amount, clerk_id, student_id) do
    changeset(%__MODULE__{}, %{amount: amount, clerk_id: clerk_id, student_id: student_id})
  end

  def changeset(tx, attrs) do
    tx
    |> cast(attrs, [:amount, :student_id, :clerk_id])
    |> validate_required([:amount, :student_id, :clerk_id])
    |> validate_number(:amount, greater_than_or_equal_to: 0)
  end

  def query_by_student_id(student_id) do
    from(
      d in __MODULE__,
      where: d.student_id == ^student_id
    )
  end

  def query_sum_by_student_id(student_id) do
    from(
      d in __MODULE__,
      where: d.student_id == ^student_id,
      select: sum(d.amount)
    )
  end
end
