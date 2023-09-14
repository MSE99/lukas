defmodule Lukas.Learning.Teaching do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  schema "teachings" do
    belongs_to(:course, Lukas.Learning.Course)
    belongs_to(:lecturer, Lukas.Accounts.User)

    timestamps()
  end

  def changeset(teaching, attrs) do
    teaching
    |> cast(attrs, [:course_id, :lecturer_id])
    |> validate_required([:course_id, :lecturer_id])
    |> unique_constraint([:course_id, :lecturer_id])
  end

  def query_course_lecturers(course_id) do
    from(
      t in __MODULE__,
      join: u in Lukas.Accounts.User,
      on: u.id == t.lecturer_id and u.kind == :lecturer,
      where: t.course_id == ^course_id,
      select: u
    )
  end

  def query_course_lecturers_ids(course_id) do
    from(
      t in __MODULE__,
      join: u in Lukas.Accounts.User,
      on: u.id == t.lecturer_id and u.kind == :lecturer,
      where: t.course_id == ^course_id,
      select: u.id
    )
  end

  def query_by_lecturer_and_course_id(course_id, lecturer_id) do
    from(
      t in __MODULE__,
      where: t.course_id == ^course_id and t.lecturer_id == ^lecturer_id
    )
  end
end
