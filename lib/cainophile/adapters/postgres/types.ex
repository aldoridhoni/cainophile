defmodule Cainophile.Adapters.Postgres.Types do
  alias PgoutputDecoder.Messages.Relation.Column

  def cast(%Column{type: {:array, inner_type}, name: name}, data) do
    {name, convert_array(inner_type, data)}
  end

  def cast(%Column{type: type, name: name}, data) do
    {name, convert("#{type}", data)}
  end

  defp convert("bool", "t"), do: true
  defp convert("bool", "f"), do: false

  defp convert(<<"float", _::binary>>, record) when is_binary(record) do
    case Float.parse(record) do
      {int, _} ->
        int

      :error ->
        record
    end
  end

  defp convert(<<"int", _::binary>>, record) when is_binary(record) do
    case Integer.parse(record) do
      {int, _} ->
        int

      :error ->
        record
    end
  end

  defp convert("timestamp", record) when is_binary(record) do
    with {:ok, %NaiveDateTime{} = naive_date_time} <- Timex.parse(record, "{RFC3339}"),
         %DateTime{} = date_time <- Timex.to_datetime(naive_date_time) do
      date_time
    else
      _ -> record
    end
  end

  defp convert("timestamptz", record) when is_binary(record) do
    case Timex.parse(record, "{RFC3339}") do
      {:ok, %DateTime{} = date_time} ->
        date_time

      _ ->
        record
    end
  end

  defp convert(<<"json", _::binary>>, record) when is_binary(record) do
    case Jason.decode(record) do
      {:ok, json} ->
        json

      _ ->
        record
    end
  end

  defp convert(_, record), do: record

  defp convert_array(inner_type, data) when is_binary(data) do
    data
    |> parse_postgres_array()
    |> Enum.map(fn
      nil -> nil
      element -> convert("#{inner_type}", element)
    end)
  end

  defp parse_postgres_array(<<"{", rest::binary>>) do
    content = String.slice(rest, 0..-2//1)

    if content == "" do
      []
    else
      ~r/"(?:\\.|[^"\\])*"|[^,{}]+/
      |> Regex.scan(content)
      |> List.flatten()
      |> Enum.map(fn
        "NULL" ->
          nil

        "\"" <> _ = quoted ->
          quoted
          |> String.slice(1..-2//1)
          |> String.replace("\\\"", "\"")
          |> String.replace("\\\\", "\\")

        val ->
          val
      end)
    end
  end

  defp parse_postgres_array(data), do: [data]
end
