defmodule Lukas.Repo.Migrations.CreateEnrollments do
  use Ecto.Migration

  def change do
    create table(:enrollments) do
      add :student_id, references(:users, on_delete: :delete_all)
      add :course_id, references(:courses, on_delete: :delete_all)

      timestamps()
    end

    create index(:enrollments, [:student_id])
    create index(:enrollments, [:course_id])
    create unique_index(:enrollments, [:student_id, :course_id])
  end
end
