defmodule Lukas.Money.TxLog do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  schema "transaction_logs" do
    field(:count, :integer)
    field(:amount, :float)

    belongs_to(:student, Lukas.Accounts.User)

    timestamps()
  end

  def new(count, student_id) do
    changeset(%__MODULE__{}, %{count: count, student_id: student_id, amount: 0})
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

  def query_last_count_for_student(student_id) do
    from(
      log in __MODULE__,
      where: log.student_id == ^student_id,
      order_by: [desc: :inserted_at],
      select: max(log.count)
    )
  end
end
