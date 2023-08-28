defmodule Lukas.Repo.Migrations.CreateTextTopics do
  use Ecto.Migration

  def change do
    create table(:topics) do
      add(:title, :string)
      add(:content, :text)
      add(:lesson_id, references(:lessons, on_delete: :nothing))

      timestamps()
    end

    create(index(:topics, [:lesson_id]))
  end
end
