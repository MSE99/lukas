defmodule Lukas.Stats do
  alias Lukas.Repo
  alias Lukas.Learning.Query

  def count_courses() do
    Query.courses_count()
    |> Repo.one()
    |> case do
      nil -> 0
      num -> num
    end
  end
end
