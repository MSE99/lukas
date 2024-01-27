defmodule Lukas.Learning.Lesson do
  use Ecto.Schema

  import Ecto.Changeset

  @default_image "default-banner.png"

  schema "lessons" do
    field(:title, :string)
    field(:description, :string)
    field(:course_id, :id)
    field(:image, :string, default: @default_image)

    timestamps()
  end

  def changeset(lesson, attrs) do
    lesson
    |> cast(attrs, [:title, :description, :course_id])
    |> validate_required([:title, :description, :course_id])
    |> validate_length(:title, min: 3, max: 80)
    |> validate_length(:description, min: 3, max: 200)
  end

  def update_image_changeset(lesson, attrs) do
    lesson
    |> cast(attrs, [:image])
    |> validate_required([:image])
  end

  def default_image(), do: @default_image
end
