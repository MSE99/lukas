defmodule Lukas.Money do
  import Lukas.Accounts.User, only: [must_be_operator: 1, must_be_student: 1]

  alias Lukas.Accounts.User
  alias Lukas.Learning.Course
  alias Lukas.Money.{TxLog, DirectDepositTx, CoursePurchase}
  alias Lukas.Repo

  alias Ecto.Multi

  def directly_deposit_to_student!(%User{} = clerk, %User{} = student, amount)
      when must_be_operator(clerk) and must_be_student(student) do
    Multi.new()
    |> Multi.one(:count, TxLog.query_last_count_for_student(student.id))
    |> Multi.insert(:deposit, DirectDepositTx.new(amount, clerk.id, student.id))
    |> Multi.run(:log, fn _, %{count: count} ->
      normalized_count = count || 0

      log =
        TxLog.new(normalized_count + 1, student.id)
        |> Repo.insert!()

      {:ok, log}
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{deposit: deposit}} -> deposit
    end
  end

  def get_deposited_amount!(%User{} = student) when must_be_student(student) do
    Multi.new()
    |> Multi.all(:deposits, DirectDepositTx.query_by_student_id(student.id))
    |> Multi.all(:purchases, CoursePurchase.query_by_buyer_id(student.id))
    |> Multi.run(:combined_txs, fn _, %{deposits: deposits, purchases: purchases} ->
      combined =
        Enum.concat(deposits, purchases)
        |> Enum.sort_by(fn tx -> tx.inserted_at end, :desc)

      {:ok, combined}
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{combined_txs: combined}} ->
        Enum.reduce(combined, 0.0, fn tx, acc -> apply_tx_to_amount(tx, acc) end)
    end
  end

  defp apply_tx_to_amount(%DirectDepositTx{} = deposit, amount), do: deposit.amount + amount
  defp apply_tx_to_amount(%CoursePurchase{} = purchase, amount), do: purchase.amount + amount
end
