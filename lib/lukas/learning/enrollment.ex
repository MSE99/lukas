defmodule Lukas.Learning.Enrollment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "enrollments" do
    belongs_to :student, Lukas.Accounts.User
    belongs_to :course, Lukas.Learning.Course

    timestamps()
  end

  def changeset(enrollment, attrs) do
    enrollment
    |> cast(attrs, [:user_id, :course_id])
    |> validate_required([:user_id, :course_id])
  end
end
