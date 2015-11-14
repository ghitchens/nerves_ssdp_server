defmodule Nerves.SSDPServer.Server do

  # NOT YET IMPLEMENTED - 13-NOV-2015

  use GenServer

  @moduledoc false

  def start_link(args) do
    state = Dict.merge(%{}, args)
    GenServer.start_link(__MODULE__, state, [])
  end
end
