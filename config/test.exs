import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :lukas, Lukas.Repo,
  database: Path.expand("../lukas_test.db", Path.dirname(__ENV__.file)),
  pool_size: 5,
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :lukas, LukasWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "n8fPXm0ZukK0osOPVDAgH1+vWfYdCEB6mEpqIINyf52GiwYAyWwR3CkCi9N7G6uF",
  server: false

# In test we don't send emails.
config :lukas, Lukas.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

config :lukas, LukasWeb.Gettext, default_locale: "en", locales: ~w(en ar)

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
