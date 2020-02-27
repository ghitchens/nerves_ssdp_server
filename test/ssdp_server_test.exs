defmodule Nerves.SSDPServerTest do

  alias Nerves.SSDPServer
  use ExUnit.Case, seed: 0

  doctest SSDPServer

  alias Nerves.SSDPClient

  @test_usn_1 "uid:test:my_usn_1"
  @test_st_1 "nerves-project-org:test-service:1"
  @test_usn_2 "uid:test:my_usn_2"
  @test_st_2 "test-nerves-project-org:another-test-service:1"

  @test_fields_1 [
    location: "http://there/",
    server: "SSDPServerTest",
    "cache-control": "max-age=1800"
  ]

  @test_fields_2 [
    location: "http://there/",
    server: "SSDPServerTest2",
    "cache-control": "max-age=5"
  ]

  test "ssdp publishing, un-publishing, re-publishing works" do
    # test publishing and behavior
    publish_and_test(@test_usn_1, @test_st_1, @test_fields_1)
    publish_and_test(@test_usn_2, @test_st_2, @test_fields_2)
    unpublish_and_test(@test_usn_1)

    publish_and_test(@test_usn_1, @test_st_1, @test_fields_1)
  end

  defp publish_and_test(usn, st, fields) do
    {:ok, ^usn} = SSDPServer.publish usn, st, fields
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
