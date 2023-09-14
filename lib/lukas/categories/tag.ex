defmodule Lukas.Categories.Tag do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tags" do
    field(:name, :string)

    has_many(:taggings, Lukas.Learning.Tagging)

    timestamps()
  end

  @doc false
  def changeset(tag, attrs) do
    tag
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
