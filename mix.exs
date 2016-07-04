defmodule Poxa.Mixfile do
  use Mix.Project

  def project do
    [ app: :poxa,
      version: "0.6.0",
      name: "Poxa",
      elixir: "~> 1.2",
      deps: deps,
      dialyzer: [
        plt_add_apps: ~w(cowboy exjsx gproc httpoison signaturex),
        plt_file: ".local.plt",
        flags: ~w(-Wunmatched_returns -Werror_handling -Wrace_conditions -Wno_opaque --fullpath --statistics)
      ]
    ]
  end

  def application do
    [ applications: [ :logger, :crypto, :gproc, :cowboy, :asn1, :public_key,
                      :ssl, :exjsx, :signaturex, :httpoison, :watcher, :ex2ms ],
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
      {:exrm, "~> 1.0.0"},
      {:conform, "~> 2.0.0"},
      {:conform_exrm, "~> 1.0"},
      {:inch_ex, "~> 0.5.1", only: :docs},
      {:httpoison, "~> 0.9"},
      {:ex2ms, "~> 1.4.0"},
      {:watcher, "~> 1.0.0"},
      {:dialyxir, "~> 0.3", only: [:dev, :test]}]
  end
end
