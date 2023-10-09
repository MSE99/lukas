defmodule Lukas.Money do
  import Lukas.Accounts.User, only: [must_be_operator: 1, must_be_student: 1]

  alias Lukas.Accounts.User
  alias Lukas.Learning.Course
  alias Lukas.Money.{TxLog, DirectDepositTx, CoursePurchase}
  alias Lukas.Repo

  alias Ecto.Multi

  def tag_from_tx(%CoursePurchase{} = c), do: "tx-purchase-#{c.id}"
  def tag_from_tx(%DirectDepositTx{} = d), do: "tx-deposit-#{d.id}"

  def describe_tx(%CoursePurchase{} = c) do
    "Course #{c.id} was purchased for #{c.amount |> :erlang.float_to_binary(decimals: 1)}"
  end

  def describe_tx(%DirectDepositTx{} = dtx) do
    "Operator with id #{dtx.id} deposited #{dtx.amount |> :erlang.float_to_binary(decimals: 1)} in your account"
  end

  def list_transactions!(%User{} = student) when must_be_student(student) do
    Multi.new()
    |> Multi.all(:deposits, DirectDepositTx.query_by_student_id(student.id))
    |> Multi.all(:purchases, CoursePurchase.query_by_buyer_id(student.id))
    |> Repo.transaction()
    |> case do
      {:ok, %{deposits: deposits, purchases: purchases}} ->
        deposits
        |> Enum.concat(purchases)
        |> Enum.sort_by(fn tx -> tx.inserted_at end, {:desc, Date})
    end
  end

  def watch_wallet(%User{} = student) when must_be_student(student) do
    Phoenix.PubSub.subscribe(Lukas.PubSub, "user/#{student.id}/wallet")
  end

  def watch_txs(%User{} = student) when must_be_student(student) do
    Phoenix.PubSub.subscribe(Lukas.PubSub, "user/#{student.id}/transactions")
  end

  def purchase_course_for(%User{} = student, %Course{} = course) when must_be_student(student) do
    purchase_course_for(Multi.new(), student, course)
  end

  def purchase_course_for(m, %User{} = student, %Course{} = course)
      when must_be_student(student) do
    m
    |> purchase_course_multi(student, course)
    |> Repo.transaction()
    |> case do
      {:ok, %{purchase: purchase, wallet_amount: wallet_amount}} = res ->
        emit_wallet_update(student, wallet_amount)
        emit_purchase(student, purchase)

        res
    end
  end

  def purchase_course_multi(m, %User{} = student, %Course{} = course) do
    m
    |> multi_log_tx(student)
    |> Multi.insert(:purchase, CoursePurchase.new(student.id, course.id, course.price))
    |> multi_current_wallet(student)
    |> Multi.run(:wallet_check, fn _, %{wallet_amount: amount} when amount >= 0 -> {:ok, nil} end)
  end

  defp emit_purchase(student, purchase) do
    Phoenix.PubSub.broadcast(
      Lukas.PubSub,
      "user/#{student.id}/transactions",
      {:transactions, student.id, :purchase_made, purchase}
    )
  end

  def directly_deposit_to_student!(%User{} = clerk, %User{} = student, amount)
      when must_be_operator(clerk) and must_be_student(student) do
    Multi.new()
    |> multi_log_tx(student)
    |> Multi.insert(:deposit, DirectDepositTx.new(amount, clerk.id, student.id))
    |> multi_current_wallet(student)
    |> Repo.transaction()
    |> case do
      {:ok, %{deposit: deposit, wallet_amount: amount}} ->
        emit_wallet_update(student, amount)
        emit_deposit(student, deposit)

        deposit
    end
  end

  defp emit_wallet_update(student, amount) do
    Phoenix.PubSub.broadcast(
      Lukas.PubSub,
      "user/#{student.id}/wallet",
      {:wallet, student.id, :amount_updated, amount}
    )
  end

  defp emit_deposit(student, deposit) do
    Phoenix.PubSub.broadcast(
      Lukas.PubSub,
      "user/#{student.id}/transactions",
      {:transactions, student.id, :deposit_made, deposit}
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