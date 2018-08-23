# Import all plugins from `rel/plugins`
# They can then be used by adding `plugin MyPlugin` to
# either an environment, or release definition, where
# `MyPlugin` is the name of the plugin module.
Path.join(["rel", "plugins", "*.exs"])
|> Path.wildcard()
|> Enum.map(&Code.eval_file(&1))

use Mix.Releases.Config,
    default_release: :default,
    default_environment: Mix.env()


environment :dev do
  set dev_mode: true
  set include_erts: false
  set cookie: :"H`|_.kDAg_~4TVZ!aB/B/S3>E|C6o|~noC_!fV/8F<^>1he.*XI^C(;7fOV1Jh;B"
end

environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: :"xR=}b(ZcHU8M1Lu&642.m{u{O)H]WD>[&&_5t8FW3t5mxy4nw=de~;lEbw*?EFXC"
end

release :poxa do
  set version: current_version(:poxa)
  set applications: [
    :runtime_tools
  ]
  plugin Conform.ReleasePlugin
end
