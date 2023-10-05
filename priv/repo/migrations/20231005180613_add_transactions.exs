defmodule Lukas.Repo.Migrations.AddTransactions do
  use Ecto.Migration

  def change() do
    create table(:tx_logs) do
      add :count, :integer
      add :amount, :float
      add :student_id, references(:users)

      timestamps()
    end

    create unique_index(:tx_logs, [:count, :student_id])
  end
end
