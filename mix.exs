defmodule Poxa.Mixfile do
  use Mix.Project

  def project do
    [ app: :poxa,
      version: "0.0.1",
      name: "Poxa",
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
                      :ranch,
                      :cowboy,
                      :erlsha2 ],
      mod: { Poxa, [] },
      env: [ port: 8080,
             app_key: "app_key",
             app_secret: "secret",
             app_id: "app_id" ]
                                ]
  end

  defp deps(:dev) do
    [ {:ranch, github: "extend/ranch", tag: "0.8.3" },
      {:cowboy, github: "extend/cowboy", tag: "0.8.4" },
      {:goldrush, github: "DeadZen/goldrush", tag: "7ff9b03"},
      {:lager, %r(.*), git: "https://github.com/basho/lager.git"},
      {:exlager, %r".*", github: "khia/exlager"},
      {:jsx, github: "talentdeficit/jsx", tag: "v1.4.1" },
      {:jsex, github: "talentdeficit/jsex"},
      {:gproc, github: "uwiger/gproc", ref: "3b32300125c491f03b728733d4b6ea9e32730ea0" },
      {:uuid, github: "avtobiff/erlang-uuid", tag: "v0.4.3" },
      {:erlsha2, github: "vinoski/erlsha2" } ]
  end

  defp deps(:test) do
    deps(:dev) ++
     [ {:meck, github: "eproxus/meck", tag: "0.7.2" } ]
  end

  defp deps(:docs) do
    deps(:dev) ++
    [ {:ex_doc, github: "elixir-lang/ex_doc" } ]
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
