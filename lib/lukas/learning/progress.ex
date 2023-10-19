defmodule Lukas.Learning.Progress do
  use Ecto.Schema

  import Ecto.Changeset

  schema "progresses" do
    belongs_to(:lesson, Lukas.Learning.Lesson)
    belongs_to(:student, Lukas.Accounts.User)
    belongs_to(:course, Lukas.Learning.Course)
    belongs_to(:topic, Lukas.Learning.Lesson.Topic)

    timestamps()
  end

  def changeset(%__MODULE__{} = prog, attrs \\ %{}) do
    prog
    |> cast(attrs, [:lesson_id, :student_id, :course_id, :topic_id])
    |> validate_required([:lesson_id, :student_id, :course_id])
  end

  def new_lesson_progress(student_id, course_id, lesson_id) do
    %__MODULE__{lesson_id: lesson_id, student_id: student_id, course_id: course_id}
  end

  def new_topic_progress(student_id, course_id, lesson_id, topic_id) do
    %__MODULE__{
      lesson_id: lesson_id,
      student_id: student_id,
      course_id: course_id,
      topic_id: topic_id
    }
  end
end
