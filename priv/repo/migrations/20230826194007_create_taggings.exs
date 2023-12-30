defmodule Lukas.Repo.Migrations.CreateTaggings do
  use Ecto.Migration

  def change() do
    create table(:taggings) do
      add(:tag_id, references(:tags, on_delete: :delete_all, on_update: :update_all))
      add(:course_id, references(:courses, on_delete: :delete_all, on_update: :update_all))

      timestamps()
    end

    create(unique_index(:taggings, [:tag_id, :course_id]))
  end
end
