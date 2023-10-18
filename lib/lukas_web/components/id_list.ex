defmodule Lukas.IdList do
  defstruct ids: [], limit: 0

  def new(ids, limit) when is_list(ids) and is_integer(limit) do
    %__MODULE__{ids: ids, limit: limit}
    |> adjust()
  end

  def unshift(%__MODULE__{} = list, next_ids) do
    %__MODULE__{list | ids: next_ids ++ list.ids}
    |> adjust()
  end

  def concat(%__MODULE__{} = list, next_ids, opts \\ []) do
    next_limit = Keyword.get(opts, :limit, list.limit)

    next_list =
      if next_limit > 0 do
        %__MODULE__{list | ids: next_ids ++ list.ids, limit: next_limit}
      else
        %__MODULE__{list | ids: list.ids ++ next_ids, limit: next_limit}
      end

    adjust(next_list)
  end

  def has?(%__MODULE__{} = list, id) do
    list
    |> Map.get(:ids)
    |> Enum.any?(fn other_id -> other_id == id end)
  end

  defp adjust(%__MODULE__{} = l) do
    next_ids =
      l
      |> Map.get(:ids)
      |> Enum.take(l.limit)

    %__MODULE__{l | ids: next_ids}
  end
end
