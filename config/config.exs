use Mix.Config
if Mix.env == :test do
  config :logger, backends: []
end

import System

config :poxa,
  port: get_env("PORT") || 8080,
  app_key: get_env("POXA_APP_KEY") || "app_key",
  app_secret: get_env("POXA_SECRET") || "secret",
  app_id: get_env("POXA_APP_ID") || "app_id"

config :gproc, gproc_dist: :all

config :renode,
  nodes: []
