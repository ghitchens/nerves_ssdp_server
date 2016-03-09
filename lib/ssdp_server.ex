defmodule Nerves.SSDPServer do

  @moduledoc """
  Implements a simplified variant of the [Simple Service Discovery Protocol]
  (https://en.wikipedia.org/wiki/Simple_Service_Discovery_Protocol).

  This does *not* use the full UPNP specification, but uses the
  multicast SSDP protocol in order to provide LAN presence annoucment
  and device discovery using a well known service type.

  It is intended to be used with Nerves.SSDPClient as part of Discovery
  of Nerves Cells.

  ```elixir
  SSDPServer.publish(options)
  ```

  Returns the same returns{:ok, pid}, wher `pid` is the pid of
  the ssdp worker.

  - service_type :: SSDP Service Type (See overview of SSDP)

  """

  @type usn :: String.t
  @type st :: String.t
  @type fields :: Dict.t
  @type reason :: atom

  use Application

  alias Nerves.SSDPServer
  alias SSDPServer.Server
  import Supervisor.Spec, warn: false

  @sup Nerves.SSDPServer.Supervisor

  @default_st "urn:nerves-project-org:service:cell:1"

  @doc false
  def start(_type, _args) do
    Supervisor.start_link [], strategy: :one_for_one, name: @sup
  end

  @doc """
  Publish the service, returning the USN (unique service name) for
  the service, which can later be used to unpublish the service.
  """
  @spec publish(usn, st, fields) :: {:ok, usn} | {:error, reason}
  def publish(usn, st, fields \\ []) do
    server_spec = worker(Server, [(st |> to_string), (usn |> to_string),
                                  fields], id: usn, restart: :transient)
    case Supervisor.start_child(@sup, server_spec) do
      {:ok, _} -> {:ok, usn}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Stop publishing the service designated by `usn`
  """
  @spec unpublish(usn) :: :ok | {:error, reason}
  def unpublish(usn) do
    Supervisor.terminate_child @sup, usn
  end

end
