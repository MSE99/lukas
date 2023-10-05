defmodule Lukas.Money.CoursePurchase do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  schema "course_purchases" do
    field(:amount, :float)

    belongs_to(:course, Lukas.Learning.Course)
    belongs_to(:buyer, Lukas.Accounts.User)

    timestamps()
  end

  def new(buyer_id, course_id, amount_paid) do
    changeset(%__MODULE__{}, %{buyer_id: buyer_id, amount: amount_paid, course_id: course_id})
  end

  def changeset(purchase, attrs \\ %{}) do
    purchase
    |> cast(attrs, [:amount, :course_id, :buyer_id])
    |> validate_required([:amount, :course_id, :buyer_id])
    |> validate_number(:amount, greater_than_or_equal_to: 0)
    |> unique_constraint([:course_id, :buyer_id])
  end

  def query_by_buyer_id(buyer_id) do
    from(
      purchase in __MODULE__,
      where: purchase.buyer_id == ^buyer_id
    )
  end

  def query_sum_by_buyer_id(buyer_id) do
    from(
      purchase in __MODULE__,
      where: purchase.buyer_id == ^buyer_id,
      select: sum(purchase.amount)
    )
  end
end
