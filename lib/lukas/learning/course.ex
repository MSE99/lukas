defmodule Lukas.Learning.Course do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  schema "courses" do
    field(:name, :string)

    has_many(:tags, Lukas.Learning.Tagging)
    has_many(:teachings, Lukas.Learning.Teaching)
    has_many(:lessons, Lukas.Learning.Lesson)

    timestamps()
  end

  def changeset(course, attrs) do
    course
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end

  def query_by_id(id) do
    from(
      c in __MODULE__,
      where: c.id == ^id
    )
  end

  def query_student_courses(student_id) do
    from(
      c in __MODULE__,
      join: enr in Lukas.Learning.Enrollment,
      on: c.id == enr.course_id,
      where: enr.student_id == ^student_id,
      select: c
    )
  end

  def query_student_courses_for_course_ids(student_id) do
    from(
      c in __MODULE__,
      join: enr in Lukas.Learning.Enrollment,
      on: enr.course_id == c.id,
      where: enr.student_id == ^student_id,
      select: c.id
    )
  end

  def query_course_not_in(not_wanted) do
    from(c in __MODULE__, where: c.id not in ^not_wanted)
  end
end
