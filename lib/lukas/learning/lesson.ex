defmodule Lukas.Learning.Lesson do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  schema "lessons" do
    field(:title, :string)
    field(:description, :string)
    field(:course_id, :id)

    timestamps()
  end

  def changeset(lesson, attrs) do
    lesson
    |> cast(attrs, [:title, :description, :course_id])
    |> validate_required([:title, :description, :course_id])
    |> validate_length(:title, min: 3, max: 80)
    |> validate_length(:description, min: 3, max: 200)
  end

  def query_by_course_id(course_id) do
    from(l in __MODULE__, where: l.course_id == ^course_id)
  end

  def query_by_id_and_course_id(lesson_id, course_id) do
    from(l in __MODULE__, where: l.course_id == ^course_id and l.id == ^lesson_id)
  end
end
