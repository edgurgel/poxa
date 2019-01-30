defmodule Poxa.Mixfile do
  use Mix.Project

  def project do
    [ app: :poxa,
      version: "0.8.1",
      name: "Poxa",
      elixir: "~> 1.5",
      deps: deps(),
      dialyzer: [
        plt_add_apps: ~w(cowboy poison gproc httpoison signaturex),
        plt_file: ".local.plt",
        flags: ~w(-Wunmatched_returns -Werror_handling -Wrace_conditions -Wno_opaque --fullpath --statistics)
      ]
    ]
  end

  def application do
    [ mod: { Poxa, [] } ]
  end

  defp deps do
    [ {:cowboy, "~> 1.1.2" },
      {:poison, "~> 3.0"},
      {:signaturex, "~> 1.3"},
      {:gproc, "~> 0.6"},
      {:mimic, "~> 0.2", only: :test},
      {:pusher_client, github: "edgurgel/pusher_client", only: :test},
      {:pusher, "~> 0.1", only: :test},
      {:distillery, "~> 1.4", runtime: false},
      {:conform, "~> 2.0"},
      {:httpoison, "~> 0.9"},
      {:ex2ms, "~> 1.5"},
      {:watcher, "~> 1.1.0"},
      {:dialyxir, "~> 0.3", only: [:dev, :test]}]
  end
end
