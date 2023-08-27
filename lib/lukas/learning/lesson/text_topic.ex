defmodule Lukas.Learning.Lesson.TextTopic do
  use Ecto.Schema
  import Ecto.Changeset

  schema "text_topics" do
    field :content, :string
    field :title, :string
    field :lesson_id, :id

    timestamps()
  end

  @doc false
  def changeset(text_topic, attrs) do
    text_topic
    |> cast(attrs, [:title, :content])
    |> validate_required([:title, :content])
  end
end
