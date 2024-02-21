defmodule Lukas.Money.Card do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

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

  def query_all_cards(opts) do
    wanted_state = Keyword.get(opts, :state, :unused)
    ordering = Keyword.get(opts, :order_by, asc: :inserted_at)
    code = Keyword.get(opts, :code, "")
    max_records = Keyword.get(opts, :limit, 50)
    offset = Keyword.get(opts, :page, 0) * max_records

    case code do
      "" ->
        from(
          c in __MODULE__,
          where: c.state == ^wanted_state,
          order_by: ^ordering
        )

      code ->
        like_str = "%" <> code <> "%"

        from(
          c in __MODULE__,
          where: c.state == ^wanted_state and like(c.code, ^like_str),
          order_by: ^ordering
        )
    end
    |> limit(^max_records)
    |> offset(^offset)
  end
end
