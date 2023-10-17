defmodule Lukas.Learning.Tagging do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  schema "taggings" do
    belongs_to(:tag, Lukas.Categories.Tag)
    belongs_to(:course, Lukas.Learning.Course)

    timestamps()
  end

  def new(tag, course) do
    %__MODULE__{tag_id: tag, course_id: course}
  end

  def changeset(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, [:tag_id, :course_id])
    |> validate_required([:tag_id, :course_id])
    |> unique_constraint([:tag_id, :course_id])
  end

  def query_by_course_id(course_id) do
    from(t in __MODULE__, where: t.course_id == ^course_id)
  end

  def query_tag_by_course_id(course_id) do
    from(
      tagging in __MODULE__,
      join: tag in Lukas.Categories.Tag,
      on: tag.id == tagging.tag_id,
      where: tagging.course_id == ^course_id,
      select: tag
    )
  end
end
