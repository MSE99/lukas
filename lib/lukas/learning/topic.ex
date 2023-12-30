defmodule Lukas.Learning.Lesson.Topic do
  use Ecto.Schema

  import Ecto.Changeset

  @kinds [:text, :video, :file]

  @default_image "default-profile.png"

  schema "topics" do
    field(:title, :string)
    field(:kind, Ecto.Enum, values: @kinds)
    field(:content, :string)
    field(:media, :string, default: @default_image)

    belongs_to(:lesson, Lukas.Learning.Lesson)

    timestamps()
  end

  def changeset(text_topic, attrs) do
    text_topic
    |> cast(attrs, [:title, :content, :lesson_id, :kind])
    |> validate_required([:title, :content, :lesson_id, :kind])
  end

  def update_changeset(text_topic, attrs) do
    text_topic
    |> cast(attrs, [:title, :content, :kind, :media])
    |> validate_required([:title, :content, :kind, :media])
  end

  def default_image(), do: @default_image
end
