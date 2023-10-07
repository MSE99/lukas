defmodule Lukas.Learning.Course do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  schema "courses" do
    field(:name, :string)
    field(:price, :float)

    has_many(:tags, Lukas.Learning.Tagging)
    has_many(:teachings, Lukas.Learning.Teaching)
    has_many(:lessons, Lukas.Learning.Lesson)

    timestamps()
  end

  def changeset(course, attrs) do
    course
    |> cast(attrs, [:name, :price])
    |> validate_required([:name, :price])
    |> validate_number(:price, greater_than_or_equal_to: 0)
  end

  def query_by_id(id) do
    from(
      c in __MODULE__,
      where: c.id == ^id
    )
  end

  def query_by_lecturer_id(lecturer_id) do
    from(
      c in __MODULE__,
      join: t in Lukas.Learning.Teaching,
      on: c.id == t.course_id,
      where: t.lecturer_id == ^lecturer_id,
      select: c
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

  def query_all_with_tags(opts) do
    limit = Keyword.get(opts, :limit, 50)
    offset = Keyword.get(opts, :offset, 0)

    from(
      c in __MODULE__,
      limit: ^limit,
      offset: ^offset,
      preload: [:tags],
      order_by: [desc: :inserted_at]
    )
  end
end
