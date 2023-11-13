defmodule Lukas.Repo.Migrations.CreateProfits do
  use Ecto.Migration

  def change() do
    create table(:profits) do
      add :amount, :float
      add :course_id, references(:courses, on_delete: :delete_all, on_update: :update_all)

      timestamps()
    end

    create index(:profits, [:course_id])
  end
end
