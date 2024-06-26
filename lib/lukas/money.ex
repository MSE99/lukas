defmodule Lukas.Money do
  import Lukas.Accounts.User, only: [must_be_operator: 1, must_be_student: 1]
  import LukasWeb.Gettext

  alias Lukas.Accounts.User
  alias Lukas.Learning.Course
  alias Lukas.Money.{TxLog, DirectDepositTx, CoursePurchase, Card}
  alias Lukas.Repo

  alias Ecto.Multi

  def delete_card(id) when is_integer(id) do
    Repo.get!(Card, id)
    |> Repo.delete()
  end

  def generate_top_up_card(value) when is_integer(value) do
    %Card{}
    |> Card.changeset(%{value: value, state: :unused, code: generate_random_top_up_card_code()})
    |> Repo.insert()
    |> maybe_emit_card_created()
  end

  defp maybe_emit_card_created({:ok, card} = res) do
    Phoenix.PubSub.broadcast(Lukas.PubSub, "cards", {:cards, :card_created, card})
    res
  end

  defp maybe_emit_card_created(res), do: res

  def list_top_up_cards(opts \\ []) do
    opts
    |> Card.query_all_cards()
    |> Repo.all()
  end

  def use_top_up_card(%User{} = student, card_code) when is_binary(card_code) do
    case Repo.get_by(Card, code: card_code) do
      %Card{state: :unused, value: value} = card ->
        Repo.delete(card)

        DirectDepositTx.new(value, nil, student.id)
        |> Repo.insert!()

        :ok

      _ ->
        {:error, :invalid_code}
    end
  end

  # TODO: find a better way to generate random numbers
  defp generate_random_top_up_card_code() do
    "#{System.unique_integer([:positive])}-#{System.unique_integer([:positive])}-#{System.unique_integer([:positive])}-#{System.unique_integer([:positive])}"
  end

  def watch_course(%Course{} = course) do
    Phoenix.PubSub.subscribe(Lukas.PubSub, "courses/#{course.id}/purchases")
  end

  def tag_from_tx(%CoursePurchase{} = c), do: "tx-purchase-#{c.id}"
  def tag_from_tx(%DirectDepositTx{} = d), do: "tx-deposit-#{d.id}"

  def describe_tx(%CoursePurchase{} = c) do
    gettext("Course %{course_id} was bought for %{amount}",
      course_id: c.id,
      amount: :erlang.float_to_binary(c.amount, decimals: 2)
    )
  end

  def describe_tx(%DirectDepositTx{clerk_id: nil} = dtx) do
    gettext(
      "You charged %{amount} to your account",
      amount: :erlang.float_to_binary(dtx.amount, decimals: 1)
    )
  end

  def describe_tx(%DirectDepositTx{} = dtx) do
    gettext(
      "Operator with id %{operator_id} deposited %{amount} in your account",
      operator_id: dtx.clerk_id,
      amount: :erlang.float_to_binary(dtx.amount, decimals: 1)
    )
  end

  def is_deposit(%DirectDepositTx{}), do: true
  def is_deposit(_), do: false

  def list_transactions!(%User{} = student) when must_be_student(student) do
    Multi.new()
    |> Multi.all(:deposits, DirectDepositTx.query_by_student_id(student.id))
    |> Multi.all(:purchases, CoursePurchase.query_by_buyer_id(student.id))
    |> Repo.transaction()
    |> case do
      {:ok, %{deposits: deposits, purchases: purchases}} ->
        deposits
        |> Enum.concat(purchases)
        |> Enum.sort_by(fn tx -> tx.inserted_at end, {:desc, NaiveDateTime})
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

    Phoenix.PubSub.broadcast(
      Lukas.PubSub,
      "courses/#{purchase.course_id}/purchases",
      {:course_purchases, purchase.course_id, :purchase_made, purchase}
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

  def calculate_course_profits(course_id) do
    course_id
    |> CoursePurchase.query_profits_by_course_id()
    |> Repo.one()
    |> case do
      nil -> 0.0
      amount -> amount
    end
  end

  def calculate_total_profits(opts \\ []) do
    before = Keyword.get(opts, :before, NaiveDateTime.utc_now())
    aft = Keyword.get(opts, :after, NaiveDateTime.add(before, -7, :day))

    CoursePurchase.query_profits(before: before, after: aft)
    |> Repo.one()
    |> case do
      nil -> 0.0
      gross_profits -> gross_profits
    end
  end

  def calculate_profits_12_months_ago() do
    now = NaiveDateTime.utc_now()

    0..12
    |> Enum.map(fn month ->
      NaiveDateTime.add(now, -(month * 7), :day)
    end)
    |> Enum.map(fn before ->
      {before, calculate_total_profits(before: before)}
    end)
  end
end
