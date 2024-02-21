defmodule Lukas.Money.Card do
  use Ecto.Schema

  import Ecto.Changeset

  schema "cards" do
    field :code, :string
    field :state, Ecto.Enum, values: [:unused, :used]
    field :value, :integer

    timestamps()
  end

  def changeset(card, attrs) do
    card
    |> cast(attrs, [:code, :value, :state])
    |> validate_required([:code, :value, :state])
  end
end
