defmodule Poxa.Mixfile do
  use Mix.Project

  def project do
    [ app: :poxa,
      version: "0.1.0",
      name: "Poxa",
      elixir: "~> 0.13.1",
      deps: deps,
      elixirc_options: options(Mix.env)]
  end

  def application do
    [ applications: [ :exlager,
                      :crypto,
                      :gproc,
                      :cowboy,
                      :signaturex,
                      :jsex,
                      :uuid ],
      mod: { Poxa, [] },
      env: [ port: 8080,
             app_key: "app_key",
             app_secret: "secret",
             app_id: "app_id" ]
                                ]
  end

  defp deps do
    [ {:cowboy, github: "extend/cowboy", tag: "0.9.0" },
      {:exlager, github: "khia/exlager"},
      {:jsex, "~> 2.0"},
      {:signaturex, "~> 0.0.2"},
      {:gproc, github: "uwiger/gproc", ref: "6e6cd7fab087edfaf7eb8a92a84d3c91cffe797c" },
      {:uuid, github: "avtobiff/erlang-uuid", tag: "v0.4.5" },
      {:meck, github: "eproxus/meck", tag: "0.8.2", only: :test},
      {:pusher_client, github: "edgurgel/pusher_client", only: :test},
      {:exrm, "0.6.4", only: :prod} ]
  end

  defp options(:dev) do
    [exlager_level: :debug, exlager_truncation_size: 8096]
  end

  defp options(:test) do
    [exlager_level: :critical, exlager_truncation_size: 8096]
  end

  defp options(_) do
  end
end
