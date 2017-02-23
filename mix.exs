defmodule Nerves.SSDPServer.Mixfile do
  use Mix.Project

  @version "0.2.2"

  def project do
    [ app: :nerves_ssdp_server,
      version: @version,
      elixir: "~> 1.4",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      description: "Client for Simple Service Discovery Protocol",
      package: package(),
      name: "Nerves.SSDPServer",
      docs: docs() ]
  end

  def application do
    [ applications: [:logger],
      mod: {Nerves.SSDPServer, []} ]
  end

  defp deps do
    [ {:nerves_ssdp_client, github: "nerves-project/nerves_ssdp_client", only: :test},
      {:ex_doc, "~> 0.11", only: :dev} ]
  end

  defp docs do
    [ source_ref: "v#{@version}",
      main: "Nerves.SSDPServer",
      source_url: "https://github.com/nerves-project/nerves_ssdp_server",
      extras: ["README.md", "CHANGELOG.md"] ]
  end

  defp package do
    [ maintainers: ["Garth Hitchens"],
      licenses: ["Apache-2.0"],
      links: %{github: "https://github.com/nerves-project/nerves_ssdp_server"},
      files: ~w(lib config) ++ ~w(README.md CHANGELOG.md LICENSE mix.exs) ]
  end
end
