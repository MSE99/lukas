defmodule Lukas.Repo do
  use Ecto.Repo,
    otp_app: :lukas,
    adapter: Ecto.Adapters.Postgres
end
