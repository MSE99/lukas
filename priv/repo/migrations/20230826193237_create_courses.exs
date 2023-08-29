defmodule Lukas.Repo.Migrations.CreateCourses do
  use Ecto.Migration

  def change do
    create table(:courses) do
      add :name, :string
      add :price, :double

      timestamps()
    end
  end
end
