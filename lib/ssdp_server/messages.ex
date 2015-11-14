defmodule Nerves.SSDPServer.Messages do

  require Logger

  @moduledoc false

  @notify_header "NOTIFY * HTTP/1.1"
  @response_header "HTTP/1.1 200 OK"

  # public

  def alive(fields) do
    Logger.debug "alive: #{inspect fields}"
    fields
    |> add_nts_field(:alive)
    |> transform_st_into_nt
    |> format_response_with_header @notify_header
  end

  def byebye(fields) do
    fields
    |> add_nts_field(:byebye)
    |> transform_st_into_nt
    |> format_response_with_header @notify_header
  end

  def reponse(fields) do
    fields
    |> format_response_with_header @response_header
  end

  # private

  defp add_nts_field(fields, nts) do
    fields
    |> Dict.merge([nts: ("ssdp:" <> :erlang.atom_to_binary(nts, :utf8))])
  end

  defp transform_st_into_nt(fields) do
    Logger.debug "transform: #{inspect fields}"
    {st, new_fields} = Dict.pop(fields, :st)
    Dict.merge(new_fields, [nt: st])
  end

  defp format_response_with_header(fields, header) do
    header <> "\r\n" <> format_fields_for_response(fields) <> "\r\n"
  end

  defp format_fields_for_response(fields) do
    Enum.map_join fields, &transform_field_into_response_line/1
  end

  defp transform_field_into_response_line({k, v}) do
    formatted_key(k) <> ": #{v}\r\n"
  end

  defp formatted_key(key) do
    key
    |> :erlang.atom_to_binary(:utf8)
    |> String.upcase
  end

end
