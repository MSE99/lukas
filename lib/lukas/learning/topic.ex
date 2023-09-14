defmodule Lukas.Learning.Lesson.Topic do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  @kinds [:text]

  schema "topics" do
    field(:title, :string)
    field(:kind, Ecto.Enum, values: @kinds)
    field(:content, :string)

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
    |> cast(attrs, [:title, :content, :kind])
    |> validate_required([:title, :content, :kind])
  end

  def query_by_lesson_id_with_no_content(lesson_id) do
    from(
      t in __MODULE__,
      where: t.lesson_id == ^lesson_id,
      select: %{
        id: t.id,
        title: t.title,
        kind: t.kind,
        inserted_at: t.inserted_at,
        lesson_id: t.lesson_id
      }
    )
  end

  def query_by_id(course_id, lesson_id, topic_id) do
    from(
      t in __MODULE__,
      join: l in Lukas.Learning.Lesson,
      on: t.lesson_id == ^lesson_id,
      where: t.id == ^topic_id and l.course_id == ^course_id and l.id == ^lesson_id
    )
  end

  def query_by_id(lesson_id, topic_id) do
    from(
      t in __MODULE__,
      where: t.id == ^topic_id and t.lesson_id == ^lesson_id
    )
  end
end
