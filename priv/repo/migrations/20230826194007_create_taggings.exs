defmodule Lukas.Repo.Migrations.CreateTaggings do
  use Ecto.Migration

  def change() do
    create table(:taggings) do
      add(:tag_id, references(:tags))
      add(:course_id, references(:courses))

      timestamps()
    end

    create(unique_index(:taggings, [:tag_id, :course_id]))
  end
end
