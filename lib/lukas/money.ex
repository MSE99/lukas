defmodule Lukas.Money do
  import Lukas.Accounts.User, only: [must_be_operator: 1, must_be_student: 1]

  alias Lukas.Accounts.User
  alias Lukas.Learning.Course
  alias Lukas.Money.{TxLog, DirectDepositTx, CoursePurchase}
  alias Lukas.Repo

  alias Ecto.Multi

  def watch_wallet(%User{} = student) when must_be_student(student) do
    Phoenix.PubSub.subscribe(Lukas.PubSub, "user/#{student.id}/wallet")
  end

  def purchase_course_for(%User{} = student, %Course{} = course) when must_be_student(student) do
    Multi.new()
    |> multi_log_tx(student)
    |> Multi.insert(:purchase, CoursePurchase.new(student.id, course.id, course.price))
    |> multi_current_wallet(student)
    |> Multi.run(:wallet_check, fn _, %{wallet_amount: amount} when amount >= 0 -> {:ok, nil} end)
    |> Repo.transaction()
    |> case do
      {:ok, %{purchase: purchase}} ->
        emit_purchase(student, purchase)

        purchase
    end
  end

  defp emit_purchase(student, purchase) do
    Phoenix.PubSub.broadcast(
      Lukas.PubSub,
      "user/#{student.id}/wallet",
      {:wallet, student.id, :purchase_made, purchase}
    )
  end

  def directly_deposit_to_student!(%User{} = clerk, %User{} = student, amount)
      when must_be_operator(clerk) and must_be_student(student) do
    Multi.new()
    |> multi_log_tx(student)
    |> Multi.insert(:deposit, DirectDepositTx.new(amount, clerk.id, student.id))
    |> Repo.transaction()
    |> case do
      {:ok, %{deposit: deposit}} ->
        emit_deposit(student, deposit)
        deposit
    end
  end

  defp emit_deposit(student, deposit) do
    Phoenix.PubSub.broadcast(
      Lukas.PubSub,
      "user/#{student.id}/wallet",
      {:wallet, student.id, :deposit_made, deposit}
    )
  end

  def get_deposited_amount!(%User{} = student) when must_be_student(student) do
    Multi.new()
    |> multi_current_wallet(student)
    |> Repo.transaction()
    |> case do
      {:ok, %{wallet_amount: wallet}} -> wallet
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

  defp multi_current_wallet(multi, student) do
    multi
    |> Multi.one(:deposits, DirectDepositTx.query_sum_by_student_id(student.id))
    |> Multi.one(:purchases, CoursePurchase.query_sum_by_buyer_id(student.id))
    |> Multi.run(:wallet_amount, fn _, %{deposits: deps, purchases: purchases} ->
      {:ok, ensure_sum_not_nil(deps) - ensure_sum_not_nil(purchases)}
    end)
  end
end
