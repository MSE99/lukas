defmodule Lukas.Learning.Course do
  use Ecto.Schema

  import Ecto.Changeset

  @default_banner_image "default-banner.png"

  schema "courses" do
    field(:name, :string)
    field(:description, :string, default: "")
    field(:price, :float)
    field(:banner_image, :string, default: @default_banner_image)

    has_many(:tags, Lukas.Learning.Tagging)
    has_many(:teachings, Lukas.Learning.Teaching)
    has_many(:lessons, Lukas.Learning.Lesson)

    timestamps()
  end

  def changeset(course, attrs) do
    course
    |> cast(attrs, [:name, :price, :banner_image, :description])
    |> validate_required([:name, :price])
    |> validate_number(:price, greater_than_or_equal_to: 0)
    |> validate_length(:description, max: 200)
  end

  def default_banner_image(), do: @default_banner_image
end
