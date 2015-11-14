defmodule Nerves.SSDPServer.Server do

  use GenServer
  require Logger

  @type state :: map

  @moduledoc false
  @initial_state %{service_type: nil, usn: nil, notify_count: 0, fields: %{}}
  @default_service_type "nerves-project-org:generic-service:1"

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, [])
  end

  def init(args) do
    Logger.debug inspect args
    @initial_state
    |> Dict.merge(state_keys_from_args(args))
    |> notify
    |> reschedule_notify
    |> tuple_reply(:ok)
  end

  @spec state_keys_from_args(Dict.t) :: Dict.t
  defp state_keys_from_args(args) do
    usn = Dict.get args, :usn
    service_type = Dict.get args, :service_type, @default_service_type
    %{service_type: service_type, usn: usn, fields: args}
  end

  @spec notify(state) :: state
  defp notify(state) do
    Logger.debug "notify: #{inspect state.usn}"
    %{state | notify_count: state.notify_count + 1}
  end

  @spec reschedule_notify(state) :: state
  defp reschedule_notify(state) do
    time_to_next_notify = notify_interval(state.notify_count)
    :erlang.send_after time_to_next_notify, Kernel.self, :notify_timer
    state
  end

  def handle_info(:notify_timer, state) do
    Logger.debug "got notify timer"
    state
    |> notify
    |> reschedule_notify
    |> tuple_reply(:noreply)
  end

  # re-notify every 2 seconds for the first 5 annoucements, then 30 secs
  defp notify_interval(count) when count >= 5, do: 30000
  defp notify_interval(_count), do: 2000

  # transform state into a reply for use with common erlang and genserver responses
  defp tuple_reply(state, atom) when is_atom(atom), do: {atom, state}

  defp build_message(state, :alive) do
    state
    |> transform_st_to_nt
    |> 
    build_message state, "NOTIFY * HTTP/1.1"
    
  end
end
