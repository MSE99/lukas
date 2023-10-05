defmodule Lukas.Money.CoursePurchase do
  use Ecto.Schema

  import Ecto.Changeset

  schema "course_purchases" do
    field :amount, :float

    belongs_to :course, Lukas.Learning.Course
    belongs_to :buyer, Lukas.Accounts.User

    timestamps()
  end

  def changeset(purchase, attrs \\ %{}) do
    purchase
    |> cast(attrs, [:amount, :course_id, :buyer_id])
    |> validate_required([:amount, :course_id, :buyer_id])
    |> validate_number(:amount, greater_than_or_equal_to: 0)
    |> unique_constraint([:course_id, :buyer_id])
  end
end
