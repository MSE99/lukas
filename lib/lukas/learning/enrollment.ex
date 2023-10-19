defmodule Lukas.Learning.Enrollment do
  use Ecto.Schema

  import Ecto.Changeset

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
end
