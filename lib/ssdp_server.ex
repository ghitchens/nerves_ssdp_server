defmodule Nerves.SSDPServer do

  @moduledoc """
  Implements a basic server for the [Simple Service Discovery Protocol]
  (https://en.wikipedia.org/wiki/Simple_Service_Discovery_Protocol).

  ```elixir
  SSDPServer.publish(usn, service_params)
  ```
  Starts an SSDP server worker that announces the service specified by the
  `usn`, or unique service name.  Since this is actuall

  Returns the same returns{:ok, pid}, wher `pid` is the pid of
  the ssdp worker.

  - service_type :: SSDP Service Type (See overview of SSDP)

  """

  @type usn :: String.t
  @type service_params :: Dict.t
  require Logger

  use Application

  alias Nerves.SSDPServer
  alias SSDPServer.Server
  import Supervisor.Spec, warn: false

  @sup Nerves.SSDPServer.Supervisor

  @doc false
  def start(_type, _args) do
    Supervisor.start_link [], strategy: :one_for_one, name: @sup
  end

  @doc """
  Publish the service designated by `usn` with associated `service_params`
  """
  def publish(usn, service_params) do
    server_args = Dict.merge([usn: usn], service_params)
    server_spec =  worker(Server, [server_args], id: usn, restart: :transient)
    Supervisor.start_child(@sup, server_spec)
  end

  @doc """
  Stop publishing the service designated by `usn`
  """
  def unpublish(usn) do
    Supervisor.terminate_child @sup, usn
  end

end
