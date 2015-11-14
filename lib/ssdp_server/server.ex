defmodule Nerves.SSDPServer.Server do

  # NOT YET IMPLEMENTED - 13-NOV-2015

  use GenServer
  require Logger

  @type state :: map

  @moduledoc false
  @initial_state %{service_type: nil, notify_count: 0}

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, [])
  end

  def init(args) do
    Logger.debug inspect args
    @initial_state
    |> Dict.merge(args)
    |> notify
    |> reschedule_notify
    |> reply(:ok)
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
    |> reply(:noreply)
  end

  # re-notify every 2 seconds for the first 5 annoucements, then 30 secs
  defp notify_interval(count) when count >= 5, do: 30000
  defp notify_interval(_count), do: 2000

  defp reply(state, atom) when is_atom(atom), do: {atom, state}

end
