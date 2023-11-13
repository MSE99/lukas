defmodule Lukas.Money.Profit do
  use Ecto.Schema

  alias Lukas.Learning.Course

  schema "profits" do
    field :amount, :float

    belongs_to :course, Course

    timestamps()
  end
end
