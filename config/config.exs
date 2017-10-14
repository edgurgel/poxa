use Mix.Config
if Mix.env == :test do
  config :logger, backends: []
end

import System

config :poxa,
  port: get_env("PORT") || 8080,
  app_key: get_env("POXA_APP_KEY") || "app_key",
  app_secret: get_env("POXA_SECRET") || "secret",
  app_id: get_env("POXA_APP_ID") || "app_id",
  registry_adapter: get_env("POXA_REGISTRY_ADAPTER") || "gproc",
  web_hook: get_env("WEB_HOOK") || nil,
  payload_limit: get_env("PAYLOAD_LIMIT") || 10_000
