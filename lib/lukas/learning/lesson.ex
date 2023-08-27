defmodule Lukas.Learning.Lesson do
  use Ecto.Schema

  import Ecto.Changeset

  schema "lessons" do
    field :title, :string
    field :description, :string
    field :course_id, :id

    timestamps()
  end

  def changeset(lesson, attrs) do
    lesson
    |> cast(attrs, [:title, :description, :course_id])
    |> validate_required([:title, :description, :course_id])
    |> validate_length(:title, min: 3, max: 80)
    |> validate_length(:description, min: 3, max: 200)
  end
end
