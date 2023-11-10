defmodule Lukas.Repo.Migrations.CreateLessons do
  use Ecto.Migration

  def change do
    create table(:lessons) do
      add :title, :string
      add :description, :string
      add :course_id, references(:courses)
      add :image, :string

      timestamps()
    end

    create index(:lessons, [:course_id])
  end
end
