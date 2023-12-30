defmodule Lukas.Repo.Migrations.CreateTeachings do
  use Ecto.Migration

  def change() do
    create table(:teachings) do
      add(:course_id, references(:courses, on_delete: :delete_all, on_update: :update_all))
      add(:lecturer_id, references(:users, on_delete: :delete_all, on_update: :update_all))

      timestamps()
    end

    create(unique_index(:teachings, [:course_id, :lecturer_id]))
  end
end
