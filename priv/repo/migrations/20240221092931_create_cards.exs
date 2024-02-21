defmodule Lukas.Repo.Migrations.CreateCards do
  use Ecto.Migration

  def change do
    create table(:cards) do
      add :code, :string
      add :value, :integer
      add :state, :string

      timestamps()
    end
  end
end
