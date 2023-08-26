defmodule Lukas.Learning.Course do
  use Ecto.Schema

  import Ecto.Changeset

  schema "courses" do
    field(:name, :string)

    has_many(:tags, Lukas.Learning.Tagging)
    has_many(:teachings, Lukas.Learning.Teaching)

    timestamps()
  end

  def changeset(course, attrs) do
    course
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> cast_assoc(:tags, &Lukas.Learning.Tagging.changeset/2)
    |> cast_assoc(:teachings, &Lukas.Learning.Teaching.changeset/2)
  end
end
