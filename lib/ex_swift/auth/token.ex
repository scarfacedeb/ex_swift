defmodule ExSwift.Auth.Token do
  use TypedStruct

  typedstruct do
    field :token, String.t(), enforce: true
    field :service_url, String.t(), enforce: true
    field :expires_at, DateTime.t(), enforce: true
    field :issued_at, DateTime.t()
    field :username, String.t()
  end

  @default_domain "Default"

  def create(%ExSwift.Config{} = config) do
    url = config.auth_url <> "/v3/auth/tokens"

    identity = %{
      methods: ["password"],
      password: %{
        user: %{
          name: config.username,
          domain: %{name: @default_domain},
          password: config.password
        }
      }
    }

    req_body =
      Jason.encode!(%{
        auth: %{identity: identity}
      })

    with {:ok, response} <- ExSwift.Http.post(url, req_body),
         {:ok, %{"token" => json}} <- Jason.decode(response.body) do
      parse(config, response, json)
    end
  end

  def parse(config, response, json) do
    struct!(__MODULE__, %{
      token: ExSwift.Http.get_header(response, "x-subject-token"),
      service_url: find_service_url(config, json["catalog"]),
      expires_at: to_datetime(json["expires_at"]),
      issued_at: to_datetime(json["issued_at"]),
      username: json["user"]["name"]
    })
  end

  def find_service_url(config, json) do
    endpoint =
      json
      |> Enum.filter(&filter_by_type(&1, config))
      |> Enum.find_value(&find_endpoint(&1, config))

    case endpoint do
      %{"url" => url} -> url
      nil -> nil
    end
  end

  def filter_by_type(%{"type" => type}, %{service_type: expected_type}),
    do: type == expected_type

  def find_endpoint(service, config) do
    case service do
      %{"endpoints" => endpoints} ->
        Enum.find(endpoints, fn endpoint ->
          endpoint["interface"] == config.interface && region_matches?(endpoint, config)
        end)

      _ ->
        false
    end
  end

  defp region_matches?(endpoint, config) do
    case config do
      %{region: nil} -> true
      %{region: region} -> endpoint["region"] == region
    end
  end

  defp to_datetime(dt_string) do
    case DateTime.from_iso8601(dt_string) do
      {:ok, dt, _} -> dt
      {:error, error} -> error
    end
  end
end
