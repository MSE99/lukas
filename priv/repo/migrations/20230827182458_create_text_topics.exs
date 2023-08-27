defmodule Lukas.Repo.Migrations.CreateTextTopics do
  use Ecto.Migration

  def change do
    create table(:text_topics) do
      add :title, :string
      add :content, :text
      add :lesson_id, references(:lessons, on_delete: :nothing)

      timestamps()
    end

    create index(:text_topics, [:lesson_id])
  end
end
