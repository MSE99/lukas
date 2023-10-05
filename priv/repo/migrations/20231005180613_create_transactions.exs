defmodule Lukas.Repo.Migrations.AddTransactions do
  use Ecto.Migration

  def change() do
    create table(:transaction_logs) do
      add(:count, :integer)
      add(:amount, :float)
      add(:student_id, references(:users))

      timestamps()
    end

    create(unique_index(:transaction_logs, [:count, :student_id]))

    create table(:direct_deposits_txs) do
      add(:amount, :float)

      add(:student_id, references(:users))
      add(:clerk_id, references(:users))

      timestamps()
    end

    create(index(:direct_deposits_txs, [:student_id]))
    create(index(:direct_deposits_txs, [:clerk_id]))

    create table(:course_purchases) do
      add(:amount, :float)
      add(:course_id, references(:courses))
      add(:buyer_id, references(:users))

      timestamps()
    end

    create(unique_index(:course_purchases, [:course_id, :buyer_id]))
    create(index(:course_purchases, [:buyer_id]))
  end
end
