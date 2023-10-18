defmodule Lukas.Learning.Enrollment do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  schema "enrollments" do
    belongs_to(:student, Lukas.Accounts.User)
    belongs_to(:course, Lukas.Learning.Course)

    timestamps()
  end

  def new(course_id, student_id) do
    %__MODULE__{}
    |> changeset(%{course_id: course_id, student_id: student_id})
  end

  def changeset(enrollment, attrs) do
    enrollment
    |> cast(attrs, [:student_id, :course_id])
    |> validate_required([:student_id, :course_id])
    |> unique_constraint([:student_id, :course_id])
  end

  def query_by_student_and_course_ids(student_id, course_id) do
    from(
      enr in __MODULE__,
      where: enr.student_id == ^student_id and enr.course_id == ^course_id
    )
  end

  def query_enrolled_students(course_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    offset = Keyword.get(opts, :offset, 0)

    from(
      enr in __MODULE__,
      join: u in Lukas.Accounts.User,
      on: enr.student_id == u.id,
      where: enr.course_id == ^course_id,
      select: u,
      limit: ^limit,
      offset: ^offset
    )
  end

  def query_enrollment_for_student(student_id, course_id) do
    from(
      enr in __MODULE__,
      where: enr.course_id == ^course_id and enr.student_id == ^student_id
    )
  end
end
