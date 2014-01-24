Code.append_path "deps/relex/ebin"
defmodule Poxa.Mixfile do
  use Mix.Project

  def project do
    [ app: :poxa,
      version: "0.0.8",
      name: "Poxa",
      elixir: "~> 0.12.2",
      deps: deps(Mix.env),
      dialyzer: [ plt_apps: ["erts","kernel", "stdlib", "crypto", "public_key", "mnesia"],
                  flags: ["-Wunmatched_returns","-Werror_handling","-Wrace_conditions"]],
      elixirc_options: options(Mix.env)]
  end

  def application do
    [ applications: [ :compiler,
                      :syntax_tools,
                      :exlager,
                      :crypto,
                      :gproc,
                      :cowboy,
                      :jsex,
                      :uuid ],
      mod: { Poxa, [] },
      env: [ port: 8080,
             app_key: "app_key",
             app_secret: "secret",
             app_id: "app_id" ]
                                ]
  end

  defp deps(:dev) do
    [ {:cowboy, github: "extend/cowboy", tag: "0.9.0" },
      {:exlager, github: "khia/exlager"},
      {:jsex, github: "talentdeficit/jsex", ref: "c9df36f07b2089a73ab6b32074c01728f1e5a2e1" },
      {:gproc, github: "uwiger/gproc", ref: "6e6cd7fab087edfaf7eb8a92a84d3c91cffe797c" },
      {:uuid, github: "avtobiff/erlang-uuid", tag: "v0.4.5" } ]
  end

  defp deps(:test) do
    deps(:dev) ++
     [ {:meck, github: "eproxus/meck", tag: "0.8"},
       {:pusher, github: "edgurgel/pusher"},
       {:pusher_client, github: "edgurgel/pusher_client"} ]
  end

  defp deps(:docs) do
    deps(:dev) ++
    [ {:ex_doc, github: "elixir-lang/ex_doc" } ]
  end

  defp deps(:prod) do
    deps(:dev) ++
    [ {:relex, github: "yrashk/relex"} ]
  end

  defp options(:dev) do
    [exlager_level: :debug, exlager_truncation_size: 8096]
  end

  defp options(:test) do
    [exlager_level: :critical, exlager_truncation_size: 8096]
  end

  defp options(_) do
  end

  if Code.ensure_loaded?(Relex.Release) do
    defmodule Release do
      use Relex.Release

      def include_erts?, do: false
      def include_elixir?, do: true
      def name, do: "poxa"
      def version, do: Mix.project[:version]
      def applications, do: [ Mix.project[:app] ]
      def lib_dirs, do: ["deps"]
    end
  end
end
