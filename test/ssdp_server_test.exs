defmodule Nerves.SSDPServerTest do
  alias Nerves.SSDPServer
  use ExUnit.Case, seed: 0

  doctest SSDPServer

  @sample_fields [
    location: "http://there/",
    st: "nerves-project-org:test-service:1",
    server: "SSDPServerTest",
    "cache-control": "max-age=1800"
  ]

  test "ssdp seems to work" do
  {:ok, _pid} = SSDPServer.publish "uuid:test:my_usn", @sample_fields
  usn = "test:my_usn_that_will_be_unpublished"
  {:ok, _pid} = SSDPServer.publish usn, @sample_fields
  :timer.sleep 1000
  :ok = SSDPServer.unpublish usn
  # {:ok, _pid} = SSDPServer.publish usn, @sample_fields
  end
end
