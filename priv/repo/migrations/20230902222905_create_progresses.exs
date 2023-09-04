defmodule Lukas.Repo.Migrations.CreateProgresses do
  use Ecto.Migration

  def change() do
    create table(:progresses) do
      add(:course_id, references(:courses, on_delete: :delete_all))
      add(:student_id, references(:users, on_delete: :delete_all))
      add(:lesson_id, references(:lessons, on_delete: :delete_all))
      add(:topic_id, references(:topics, on_delete: :delete_all))

      timestamps()
    end

    create(unique_index(:progresses, [:course_id, :student_id, :lesson_id, :topic_id]))
  end
end
