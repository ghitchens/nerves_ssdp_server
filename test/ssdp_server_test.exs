defmodule Nerves.SSDPServerTest do
  alias Nerves.SSDPServer
  use ExUnit.Case

  doctest SSDPServer

  test "publishing doesn't crash" do
    {:ok, _pid} = SSDPServer.publish "test:my_usn", url: "http://here/"
  end

  test "publishing and unpublishing works properly" do
    usn = "test:my_usn_that_will_be_unpublished"
    {:ok, _pid} = SSDPServer.publish usn, url: "http://there/"
    :ok = SSDPServer.unpublish usn
  end
end
