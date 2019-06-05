defmodule ExSwift.Response do
  @moduledoc """
  Thin wrapper around Mojito.Response.

  It allows to store parsed json in the Response struct.
  """

  use TypedStruct

  typedstruct do
    field :status_code, pos_integer()
    field :headers, [{String.t(), String.t()}]
    field :body, String.t() | map() | list()
    field :json?, bool()
  end

  @doc "Transform Mojito.Response into ExSwift.Response"
  @spec from_mojito(Mojito.Response.t()) :: t()
  def from_mojito(%Mojito.Response{} = response) do
    {json, body} = parse_json(response)

    struct!(__MODULE__, %{
      status_code: response.status_code,
      headers: response.headers,
      body: body,
      json?: json
    })
  end

  defp parse_json(response) do
    case ExSwift.Request.get_header(response, "content-type") do
      <<"application/json", _::binary>> ->
        {true, decode(response.body)}

      _ ->
        {false, response.body}
    end
  end

  defp decode(""), do: %{}
  defp decode(body), do: Jason.decode!(body)
end
