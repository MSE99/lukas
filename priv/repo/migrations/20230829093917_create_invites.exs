defmodule Lukas.Repo.Migrations.CreateInvites do
  use Ecto.Migration

  def change do
    create table(:invites) do
      add :kind, :string
      add :code, :string

      timestamps()
    end

    create unique_index(:invites, :code)
  end
end
