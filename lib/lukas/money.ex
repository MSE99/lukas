defmodule Lukas.Money do
  import Lukas.Accounts.User, only: [must_be_operator: 1, must_be_student: 1]

  alias Lukas.Accounts.User
  alias Lukas.Learning.Course
  alias Lukas.Money.{TxLog, DirectDepositTx, CoursePurchase}
  alias Lukas.Repo

  alias Ecto.Multi

  def purchase_course_for(%User{} = student, %Course{} = course) when must_be_student(student) do
    Multi.new()
    |> multi_log_tx(student)
    |> Multi.insert(:purchase, CoursePurchase.new(student.id, course.id, course.price))
    |> Repo.transaction()
    |> case do
      {:ok, %{purchase: purchase}} -> purchase
    end
  end

  def directly_deposit_to_student!(%User{} = clerk, %User{} = student, amount)
      when must_be_operator(clerk) and must_be_student(student) do
    Multi.new()
    |> multi_log_tx(student)
    |> Multi.insert(:deposit, DirectDepositTx.new(amount, clerk.id, student.id))
    |> Repo.transaction()
    |> case do
      {:ok, %{deposit: deposit}} -> deposit
    end
  end

  def get_deposited_amount!(%User{} = student) when must_be_student(student) do
    Multi.new()
    |> Multi.one(:deposits, DirectDepositTx.query_sum_by_student_id(student.id))
    |> Multi.one(:purchases, CoursePurchase.query_sum_by_buyer_id(student.id))
    |> Repo.transaction()
    |> case do
      {:ok, %{deposits: deposits, purchases: purchases}} ->
        ensure_sum_not_nil(deposits) - ensure_sum_not_nil(purchases)
    end
  end

  defp ensure_sum_not_nil(nil), do: 0.0
  defp ensure_sum_not_nil(sum), do: sum

  defp multi_log_tx(multi, student) do
    multi
    |> Multi.one(:count, TxLog.query_last_count_for_student(student.id))
    |> Multi.run(:log, fn _, %{count: count} ->
      normalized_count = count || 0

      log =
        TxLog.new(normalized_count + 1, student.id)
        |> Repo.insert!()

      {:ok, log}
    end)
  end
end
