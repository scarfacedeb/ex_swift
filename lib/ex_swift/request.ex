defmodule ExSwift.Request do
  @moduledoc """
  Wrapper around Mojito library to make HTTP requests to Swift API.
  """

  use TypedStruct
  alias ExSwift.{Request, Response, Config}

  typedstruct do
    field :method, atom() | String.t()
    field :path, String.t()
    field :headers, [{String.t(), String.t()}], default: []
    field :body, String.t(), default: ""
    field :params, map(), default: %{}
  end

  @accept_header {"accept", "application/json"}
  @ssl_opts [transport_opts: [verify: :verify_none]]

  @doc "Run request struct and return Mojito response struct"
  @spec run(Request.t(), Config.t()) :: {:ok, Response.t()} | {:error, any()}
  def run(%Request{} = request, %Config{token: token}) do
    headers = [@accept_header, {"X-Auth-Token", token.token}] ++ request.headers

    %Mojito.Request{
      method: request.method,
      url: build_url(token, request),
      headers: headers,
      body: request.body,
      opts: @ssl_opts
    }
    |> Mojito.request()
    |> handle_response()
  end

  defp build_url(%{service_url: base_url}, %{path: path, params: params}) do
    base_url
    |> URI.parse()
    |> Map.update!(:path, &(&1 <> path))
    |> Map.put(:query, URI.encode_query(params))
    |> URI.to_string()
  end

  defp handle_response(response_tuple) do
    case response_tuple do
      {:ok, %Mojito.Response{status_code: status} = resp} when status in 200..299 ->
        {:ok, Response.from_mojito(resp)}

      {:ok, %Mojito.Response{status_code: status} = resp} ->
        {:error, {:http_error, status, resp}}

      {:error, error} ->
        {:error, error}
    end
  end

  @doc "Send request to get new auth token"
  @spec create_token(String.t(), map()) :: {:ok, Response.t()} | {:error, any()}
  def create_token(url, body) do
    headers = [{"content-type", "application/json"}]
    req_body = Jason.encode!(body)

    %Mojito.Request{
      method: :post,
      url: url,
      headers: headers,
      body: req_body
    }
    |> Mojito.request()
    |> handle_response()
  end

  @doc "Get header value from response"
  @spec get_header(Response.t() | Mojito.Response.t(), String.t()) :: String.t() | nil
  def get_header(%{headers: headers}, name) do
    Mojito.Headers.get(headers, name)
  end
end
