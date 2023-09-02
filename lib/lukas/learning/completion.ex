defmodule Lukas.Learning.Lesson.Completion do
  use Ecto.Schema

  schema "completions" do
    belongs_to :lesson, Lukas.Learning.Lesson
    belongs_to :student, Lukas.Accounts.User
    belongs_to :course, Lukas.Learning.Course
    belongs_to :topic, Lukas.Learning.Lesson.Topic

    timestamps()
  end
end
