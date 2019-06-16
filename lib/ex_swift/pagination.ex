defmodule ExSwift.Pagination do
  @moduledoc """
  Helper module to create streams out of paginated API results.
  """

  @type opts :: list()
  @type stream_builder_return :: {:ok, %{body: list()}} | {:error, any()}
  @type stream_builder_fn :: (opts() -> stream_builder_return())

  @default_page_limit 500

  @doc "Create stream for paginated results"
  @spec stream!(stream_builder_fn(), opts()) :: Enumerable.t()
  def stream!(stream_builder_fn, overrides \\ []) do
    opts =
      %{limit: @default_page_limit, marker: nil}
      |> Map.merge(Map.new(overrides))

    Stream.resource(
      fn -> opts end,
      &next_page(&1, stream_builder_fn),
      fn _ -> nil end
    )
  end

  defp next_page(:last_page, _), do: {:halt, nil}

  defp next_page(%{limit: limit} = opts, stream_builder_fn) do
    case stream_builder_fn.(opts) do
      {:ok, %{body: items}} when length(items) < limit ->
        {items, :last_page}

      {:ok, %{body: items}} when is_list(items) ->
        last_item = items |> List.last()
        {items, %{opts | marker: last_item["name"]}}

      {:error, error} ->
        error |> inspect() |> raise()
    end
  end
end
