defmodule Nerves.SSDPServerTest do

  alias Nerves.SSDPServer
  use ExUnit.Case, seed: 0

  doctest SSDPServer

  alias Nerves.SSDPClient

  @test_usn_1 "uid:test:my_usn_1"
  @test_usn_2 "uid:test:my_usn_2"

  @test_fields_1 [
    location: "http://there/",
    st: "nerves-project-org:test-service:1",
    server: "SSDPServerTest",
    "cache-control": "max-age=1800"
  ]

  @test_fields_2 [
    location: "http://there/",
    st: "test-nerves-project-org:another-test-service:1",
    server: "SSDPServerTest2",
    "cache-control": "max-age=5"
  ]

  test "ssdp publishing, un-publishing works" do
    # test publishing and behavior
    publish_and_test(@test_usn_1, @test_fields_1)
    publish_and_test(@test_usn_2, @test_fields_2)
    unpublish_and_test @test_usn_1
  end

  defp publish_and_test(usn, fields) do
    {:ok, _pid} = SSDPServer.publish usn, fields
    responses = SSDPClient.discover
    response = responses[usn]
    assert is_map(response)
    Enum.each fields, fn({k,v}) ->
      assert response[k] == v
    end
  end

  defp unpublish_and_test(usn) do
    :ok = SSDPServer.unpublish usn
    :timer.sleep 1000
    responses = SSDPClient.discover
    assert responses[usn] == nil
  end
end
