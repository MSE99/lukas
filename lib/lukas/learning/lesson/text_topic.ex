defmodule Lukas.Learning.Lesson.TextTopic do
  use Ecto.Schema
  import Ecto.Changeset

  schema "text_topics" do
    field(:content, :string)
    field(:title, :string)

    belongs_to(:lesson, Lukas.Learning.Lesson)

    timestamps()
  end

  def changeset(text_topic, attrs) do
    text_topic
    |> cast(attrs, [:title, :content, :lesson_id])
    |> validate_required([:title, :content, :lesson_id])
  end
end
