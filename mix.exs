defmodule Nerves.SSDPServer.Mixfile do

  use Mix.Project

  def project do
    [app: :nerves_ssdp_server,
     version: "0.2.0",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application, do: [
    applications: [:logger],
    mod: {Nerves.SSDPServer, []}
  ]

  defp deps, do: [
    {:nerves_ssdp_client, github: "nerves-project/nerves_ssdp_client", only: :test}
  ]

end
