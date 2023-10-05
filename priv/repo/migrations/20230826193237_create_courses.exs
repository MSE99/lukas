defmodule Lukas.Repo.Migrations.CreateCourses do
  use Ecto.Migration

  def change do
    create table(:courses) do
      add(:name, :string)
      add(:price, :float)

      timestamps()
    end
  end
end
