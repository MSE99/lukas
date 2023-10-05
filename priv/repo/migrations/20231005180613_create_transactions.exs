defmodule Lukas.Repo.Migrations.AddTransactions do
  use Ecto.Migration

  def change() do
    create table(:tx_logs) do
      add(:count, :integer)
      add(:amount, :float)
      add(:student_id, references(:users))

      timestamps()
    end

    create(unique_index(:tx_logs, [:count, :student_id]))

    create table(:direct_deposits) do
      add(:kind, :string)
      add(:amount, :float)

      add(:student, references(:users))
      add(:clerk, references(:users))

      timestamps()
    end

    create(index(:direct_deposits, [:student]))
    create(index(:direct_deposits, [:clerk]))

    create table(:course_purchases) do
      add :amount, :float
      add :course_id, references(:courses)
      add :buyer_id, references(:users)

      timestamps()
    end

    create unique_index(:course_purchases, [:course_id, :buyer_id])
    create index(:course_purchases, [:buyer_id])
  end
end
