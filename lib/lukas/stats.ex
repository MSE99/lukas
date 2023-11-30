defmodule Lukas.Stats do
  alias Lukas.Repo
  alias Lukas.{Learning, Accounts, Money}

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

  def get_total_earnings(), do: Money.calculate_total_profits()
end
