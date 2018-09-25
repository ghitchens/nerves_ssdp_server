defmodule Nerves.SSDPServer do

  @moduledoc """
  Implements a simple subset of the [Simple Service Discovery Protocol](https://en.wikipedia.org/wiki/Simple_Service_Discovery_Protocol).

  This does *not* implement the full UPNP specification, but uses the
  multicast SSDP protocol in order to provide LAN presence annoucment
  and device discovery.
  """

  @typedoc """
  Unique Service Identifier -- Uniquely identifies the service, and must be unique on the local network.
  """
  @type usn :: String.t

  @typedoc """
  Service Type -- a string that identifies the type of SSDP service.
  """

  @type st :: String.t
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
  Publish the service, returning the USN (unique service name) for
  the service, which can later be used to unpublish the service.

  - `usn` (unique service name) - uniquely identifies the service, and must be
    unique on the local network. attempts to publish two services with the same
    usn on the same node will result in an error.

  - `st` (service type) :: SSDP Service Type - a string that identifies the
    type of service.

  - `fields` - Keyword list consiting of fields ot be added to the SSDP replies.

  ## Examples

  ### Simple Publishing

      Nerves.SSDPServer.publish "my_unique_service_name", "my-service-type"

  ### Publishing custom fields

  Other parameters you might specify for the second paramter do `publish` are
  included as fields of the published service. For instance, you can do..

      @ssdp_fields [
          location: "http://localhost:3000/myservice.json",
          server: "MyServerName",
          "cache-control": "max-age=1800"
      ]

      Nerves.SSDPServer.publish "my-service-name", "my-service-type", @ssdp_fields
  """
  @spec publish(usn, st, Keyword.t) :: {:ok, usn} | {:error, atom}
  def publish(usn, st, fields \\ []) do
    ssdp_worker = worker(Server, [
      (st |> to_string), (usn |> to_string), fields],
      id: usn, restart: :transient)
    Supervisor.start_child(@sup, ssdp_worker)
    |> case do
      {:ok, _pid} -> {:ok, usn}
      other -> other
    end
  end

  @doc """
  Stop publishing the service designated by `usn`.
  """
  @spec unpublish(usn) :: :ok | {:error, atom}
  def unpublish(usn) do
    Supervisor.terminate_child(@sup, usn)
    Supervisor.delete_child(@sup, usn)
  end

end
