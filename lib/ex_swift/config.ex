defmodule ExSwift.Config do
  use TypedStruct

  typedstruct do
    field :auth_url, String.t(), enforce: true
    field :username, String.t(), enforce: true
    field :password, String.t(), enforce: true
    field :token, ExSwift.Auth.Token.t()

    field :service_type, String.t(), default: "object-store"
    field :interface, String.t(), default: "public"
    field :region, String.t() | nil
  end

  def new(opts \\ []) do
    overrides = Map.new(opts)
    env = Application.get_all_env(:ex_swift)
    config = env |> Map.new() |> Map.merge(overrides)

    __MODULE__
    |> struct!(config)
    |> retrieve_token()
  end

  def retrieve_token(config) do
    token = ExSwift.Auth.get_token!(config)
    Map.put(config, :token, token)
  end
end
