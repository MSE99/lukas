defmodule Lukas.Repo.Migrations.CreateTeachings do
  use Ecto.Migration

  def change() do
    create table(:teachings) do
      add(:course_id, references(:courses))
      add(:lecturer_id, references(:lecturers))

      timestamps()
    end

    create(unique_index(:teachings, [:course_id, :lecturer_id]))
  end
end
