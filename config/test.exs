import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :generator_racuna, GeneratorRacunaWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "7GJPm66v/y/cdgrJJ/h3kTTd/S/D+uj9Gbm7ake2a58RN4L5c3v4wsDycGILbxI4",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
