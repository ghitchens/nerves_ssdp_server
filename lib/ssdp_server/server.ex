defmodule Nerves.SSDPServer.Server do
  alias Nerves.SSDPServer.Messages
  use GenServer

  @type state :: map

  @moduledoc false

  @initial_state %{
    st: nil,
    recv_socket: nil,
    xmit_socket: nil,
    usn: nil,
    notify_count: 0,
    fields: []
  }

  def start_link(st, usn, fields) do
    GenServer.start_link(__MODULE__, [st, usn, fields], [])
  end

  # public genserver handlers

  def init([st, usn, fields]) do
    @initial_state
    |> Map.merge(%{st: st, usn: usn, fields: fields})
    |> open_ssdp_sockets!
    |> notify!
    |> reschedule_notify!
    |> tuple_reply(:ok)
  end

  # handle received udp m-search packets and ignore all others

  @msearch "M-SEARCH * HTTP/1.1"

  def handle_info({:udp, _s, ip, port, <<@msearch, rest::binary>>}, state) do
    state
    |> handle_msearch(ip, port, rest)
    |> tuple_reply(:noreply)
  end

  def handle_info({:udp, _s, _ip, _port, _}, state), do: {:noreply, state}

  # timer handlers for notify and m-search response

  def handle_info(:notify_timer, state) do
    state
    |> notify!
    |> reschedule_notify!
    |> tuple_reply(:noreply)
  end

  def handle_info({:respond_timer, ip, port}, state) do
    state
    |> respond!(ip, port)
    |> tuple_reply(:noreply)
  end

  # ssdp m-search & reply handling (private)

  @default_search_target "ssdp:all"
  defp handle_msearch(state, ip, port, packet) do
    headers = packet |> parse_httpu_headers
    search_target = headers[:st] || @default_search_target

    if m_search_matches?(search_target, state.st) do
      headers
      |> response_time
      |> :erlang.send_after(Kernel.self(), {:respond_timer, ip, port})
    end

    state
  end

  @default_mx 3000
  @spec response_time(Keyword.t()) :: integer
  # return random time in milliseconds (0-MX)
  defp response_time(headers) do
    if headers[:mx] do
      String.to_integer(headers[:mx]) * 1000
    else
      @default_mx
    end
    |> :rand.uniform()
  end

  defp respond!(state, ip, port) do
    message = Messages.response(state.usn, state.st, state.fields)
    :gen_udp.send(state.xmit_socket, ip, port, message)
    state
  end

  # search match definitions

  def m_search_matches?("ssdp:all", _st), do: true
  def m_search_matches?(target, st), do: String.equivalent?(target, st)

  # ssdp notification (private)

  # after 5 notifies slow downd
  @slow_notify_after 5
  # every 3 seconds at first
  @fast_notify_interval 3000
  # 30 seconds thereafter
  @slow_notify_interval 30000

  @spec notify!(state) :: state
  defp notify!(state) do
    Messages.alive(state.usn, state.st, state.fields)
    |> send_multicast_ssdp_message!(state.xmit_socket)
    |> case do
      :ok -> %{state | notify_count: state.notify_count + 1}
      _ -> state
    end
  end

  @spec reschedule_notify!(state) :: state
  defp reschedule_notify!(state) do
    time_to_next_notify = notify_interval(state.notify_count)
    :erlang.send_after(time_to_next_notify, Kernel.self(), :notify_timer)
    state
  end

  defp notify_interval(notify_count) do
    if notify_count > @slow_notify_after do
      @slow_notify_interval
    else
      @fast_notify_interval
    end
  end

  # socket management (private)

  @mcast_group {239, 255, 255, 250}
  @mcast_port 1900

  defp open_ssdp_sockets!(state) do
    {:ok, recv_socket} = :gen_udp.open(@mcast_port, recv_socket_opts(state))
    {:ok, xmit_socket} = :gen_udp.open(0, xmit_socket_opts(state))
    %{state | recv_socket: recv_socket, xmit_socket: xmit_socket}
  end

  defp recv_socket_opts(state),
    do: [
      ip: @mcast_group,
      active: true,
      mode: :binary,
      reuseaddr: true,
      multicast_loop: true,
      add_membership: {@mcast_group, multicast_if(state)}
      # multicast_if: multicast_if(state),
      # broadcast: true,
    ]

  defp xmit_socket_opts(_state),
    do: [
      reuseaddr: true,
      mode: :binary,
      multicast_loop: true,
      multicast_ttl: 4
      # multicast_if: multicast_if(state),
    ]

  defp multicast_if(_state) do
    {0, 0, 0, 0}
  end

  defp send_multicast_ssdp_message!(message, socket) do
    :gen_udp.send(socket, @mcast_group, @mcast_port, message)
  end

  # transform state into a reply for use with common erlang and genserver responses
  defp tuple_reply(state, atom) when is_atom(atom), do: {atom, state}

  defp parse_httpu_headers(packet) do
    raw_params = String.split(packet, ["\r\n", "\n"])

    mapped_params =
      Enum.map(raw_params, fn x ->
        case String.split(x, ":", parts: 2) do
          [k, v] -> {String.to_atom(String.downcase(k)), String.trim(v)}
          _ -> nil
        end
      end)

    Enum.reject(mapped_params, &(&1 == nil))
  end
end
