defmodule Lukas.Repo.Migrations.CreateTextTopics do
  use Ecto.Migration

  def change do
    create table(:topics) do
      add(:title, :string)
      add(:kind, :string)
      add(:content, :string)
      add(:lesson_id, references(:lessons, on_delete: :delete_all, on_update: :update_all))

      timestamps()
    end

    create(index(:topics, [:lesson_id]))
  end
end
