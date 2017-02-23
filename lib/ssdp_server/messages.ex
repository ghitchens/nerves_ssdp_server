defmodule Nerves.SSDPServer.Messages do

  @moduledoc false
  @notify_header "NOTIFY * HTTP/1.1"
  @response_header "HTTP/1.1 200 OK"

  def alive(usn, st, fields) do
    fields
    |> Keyword.merge(nt: st, usn: usn, nts: "ssdp:alive")
    |> format_response_with_header(@notify_header)
  end

  def byebye(usn, st, fields) do
    fields
    |> Keyword.merge(nt: st, usn: usn, nts: "ssdp:byebye")
    |> format_response_with_header(@notify_header)
  end

  def response(usn, st, fields) do
    fields
    |> Keyword.merge(st: st, usn: usn)
    |> format_response_with_header(@response_header)
  end

  # private

  defp format_response_with_header(fields, header) do
    header <> "\r\n" <> format_fields_for_response(fields) <> "\r\n"
  end

  defp format_fields_for_response(fields) do
    Enum.map_join fields, &transform_field_into_response_line/1
  end

  defp transform_field_into_response_line({k, v}) do
    formatted_key(k) <> ": " <> formatted_value(v) <> "\r\n"
  end

  defp formatted_key(key) do
    key
    |> :erlang.atom_to_binary(:utf8)
    |> String.upcase
  end

  defp formatted_value(v) when is_function(v), do: v.()
  defp formatted_value(v), do: to_string(v)

end
