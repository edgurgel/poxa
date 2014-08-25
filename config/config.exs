use Mix.Config
if Mix.env == :test do
  config :logger, backends: []
end

config :poxa,
  port: 8080,
  app_key: "app_key",
  app_secret: "secret",
  app_id: "app_id"
