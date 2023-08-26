defmodule Lukas.Learning.Teaching do
  use Ecto.Schema

  import Ecto.Changeset

  schema "teachings" do
    belongs_to(:course, Lukas.Learning.Course)
    belongs_to(:lecturer, Lukas.Accounts.User)

    timestamps()
  end

  def changeset(teaching, attrs) do
    teaching
    |> cast(attrs, [:course_id, :lecturer_id])
    |> validate_required([:course_id, :lecturer_id])
    |> unique_constraint([:course_id, :lecturer_id])
  end
end
