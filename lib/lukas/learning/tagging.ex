defmodule Lukas.Learning.Tagging do
  use Ecto.Schema

  import Ecto.Changeset

  schema "taggings" do
    belongs_to(:tag, Lukas.Learning.Tag)
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
end
