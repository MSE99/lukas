defmodule Lukas.Repo.Migrations.CreateCourses do
  use Ecto.Migration

  def change do
    create table(:courses) do
      add(:name, :string)
      add(:description, :string)
      add(:price, :float)
      add(:banner_image, :string)

      timestamps()
    end
  end
end
