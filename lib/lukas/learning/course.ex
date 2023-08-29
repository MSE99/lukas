defmodule Lukas.Learning.Course do
  use Ecto.Schema

  import Ecto.Changeset

  schema "courses" do
    field(:name, :string)
    field(:price, :float, default: 0.0)

    has_many(:tags, Lukas.Learning.Tagging)
    has_many(:teachings, Lukas.Learning.Teaching)
    has_many(:lessons, Lukas.Learning.Lesson)

    timestamps()
  end

  def changeset(course, attrs) do
    course
    |> cast(attrs, [:name, :price])
    |> validate_required([:name])
    |> validate_number(:price, min: 0)
  end
end
