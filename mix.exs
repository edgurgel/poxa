defmodule Poxa.Mixfile do
  use Mix.Project

  def project do
    [
      app: :poxa,
      version: "1.0.0",
      name: "Poxa",
      elixir: "~> 1.9",
      deps: deps(),
      dialyzer: [
        plt_add_apps: ~w(cowboy poison gproc httpoison signaturex),
        plt_file: ".local.plt",
        flags:
          ~w(-Wunmatched_returns -Werror_handling -Wrace_conditions -Wno_opaque --fullpath --statistics)
      ]
    ]
  end

  def application do
    [extra_applications: [:logger], mod: {Poxa, []}]
  end

  defp deps do
    [
      {:cowboy, "~> 2.6"},
      {:jason, "~> 1.0"},
      {:signaturex, "~> 1.3"},
      {:gproc, "~> 0.8"},
      {:mimic, "~> 1.0", only: :test},
      {:pusher, "~> 2.1", only: :test},
      {:httpoison, "~> 1.0"},
      {:ex2ms, "~> 1.5"},
      {:dialyxir, "~> 0.3", only: [:dev, :test]}
    ]
  end
end
