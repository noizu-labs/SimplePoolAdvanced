#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.AdvancedPool.Mixfile do
  use Mix.Project
  
  def project do
    [app: :noizu_advanced_pool,
      version: "3.0.5",
      elixir: "~> 1.9",
      package: package(),
      deps: deps(),
      description: "Noizu Simple Pool Advanced",
      docs: docs(),
      elixirc_paths: elixirc_paths(Mix.env),
      xref: [exclude: [Noizu.FastGlobal.Cluster]]
    ]
  end # end project
  
  defp package do
    [
      maintainers: ["noizu", "lacrossetech"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/noizu-labs/AdvancedPool"}
    ]
  end # end package
  
  def application do
    [
      applications: [:logger, :poison],
      #extra_applications: [:semaphore, :fastglobal, :noizu_mnesia_versioning, :noizu_advanced_scaffolding, :noizu_core, :amnesia]
      extra_applications: [:noizu_core, :syn] ++ (if Mix.env == :test, do: [:amnesia, :elixir_uuid], else: [])
    ]
  end # end application
  
  def deps do
    [
      {:ex_doc, "~> 0.16.2", only: [:dev, :test], optional: true}, # Documentation Provider
      {:markdown, github: "devinus/markdown", ref: "d065dbc", only: [:dev], optional: true}, # Markdown processor for ex_doc
      {:noizu_core, github: "noizu-labs/ElixirCore", tag: "1.0.26"},
      {:syn, "~> 3.3"},
      #      {:noizu_advanced_scaffolding, github: "noizu-labs/advanced_elixir_scaffolding", branch: "master", override: true},
      #      {:noizu_mnesia_versioning, github: "noizu/MnesiaVersioning", tag: "0.1.10", override: true},
      #      {:plug, "~> 1.11.1", optional: true},
      {:elixir_uuid, "~> 1.2", optional: true},
      {:telemetry, "~> 1.1.0", optional: true, override: true},
      {:poison, "~> 3.1.0", override: true},
      #      {:fastglobal, "~> 1.0"}, # https://github.com/discordapp/fastglobal
      #      {:semaphore, "~> 1.0"}, # https://github.com/discordapp/semaphore
    ]
  end # end deps
  
  defp docs do
    [
      source_url_pattern: "https://github.com/noizu-labs/AdvancedPool/blob/master/%{path}#L%{line}",
      extras: ["README.md"]
    ]
  end # end docs
  
  defp elixirc_paths(:test), do: ["lib","test/support"]
  defp elixirc_paths(_), do: ["lib"]

end
