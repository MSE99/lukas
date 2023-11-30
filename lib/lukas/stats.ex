defmodule Lukas.Stats do
  alias Lukas.Repo
  alias Lukas.Learning
  alias Lukas.Accounts

  def count_courses() do
    Learning.Query.courses_count()
    |> Repo.one()
    |> case do
      nil -> 0
      num -> num
    end
  end

  def count_students() do
    Accounts.Query.count_students()
    |> IO.inspect()
    |> Repo.one()
    |> case do
      nil -> 0
      count -> count
    end
  end
end
