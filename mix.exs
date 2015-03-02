defmodule Poxa.Mixfile do
  use Mix.Project

  def project do
    [ app: :poxa,
      version: "0.4.0",
      name: "Poxa",
      elixir: "~> 1.0.0",
      deps: deps ]
  end

  def application do
    [ applications: [ :logger,
                      :crypto,
                      :gproc,
                      :renode,
                      :locks,
                      :cowboy ],
      included_applications: [ :exjsx, :uuid, :signaturex ],
      mod: { Poxa, [] } ]
  end

  defp deps do
    [ {:cowboy, "~> 1.0.0" },
      {:exjsx, "~> 3.0"},
      {:signaturex, "~> 0.0.8"},
      {:gproc, github: "uwiger/gproc", branch: "uw-locks_leader"},
      {:locks, github: "uwiger/locks"},
      {:renode, github: "edgurgel/renode"},
      {:uuid, github: "avtobiff/erlang-uuid", tag: "v0.4.5" },
      {:meck, "~> 0.8.2", only: :test},
      {:pusher_client, github: "edgurgel/pusher_client", only: :test},
      {:pusher, github: "edgurgel/pusher", only: :test},
      {:exrm, "0.14.9", only: :prod},
      {:inch_ex, only: :docs} ]
  end
end
