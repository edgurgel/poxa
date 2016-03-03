defmodule Poxa.Mixfile do
  use Mix.Project

  def project do
    [ app: :poxa,
      version: "0.6.0",
      name: "Poxa",
      elixir: "~> 1.1",
      deps: deps ]
  end

  def application do
    [ applications: [ :logger, :crypto, :gproc, :cowboy, :asn1, :public_key, :ssl, :exjsx, :signaturex, :httpoison, :watcher ],
      mod: { Poxa, [] } ]
  end

  defp deps do
    [ {:cowboy, "~> 1.0.0" },
      {:exjsx, "~> 3.0"},
      {:signaturex, "~> 1.0"},
      {:gproc, "~> 0.3.0"},
      {:meck, "~> 0.8.2", only: :test},
      {:pusher_client, github: "edgurgel/pusher_client", only: :test},
      {:pusher, "~> 0.1", only: :test},
      {:exrm, "~> 0.19.2", only: :prod},
      {:edip, "~> 0.4", only: :prod},
      {:inch_ex, "~> 0.5.1", only: :docs},
      {:httpoison, "~> 0.8"},
      {:watcher, "~> 1.0.0"} ]
  end
end
