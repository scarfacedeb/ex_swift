defmodule ExSwift.Auth do
  @doc "Get authnetication token from cache or auth endpoint"
  @spec get_token(ExSwift.Config.t()) :: ExSwift.Auth.Token.t()
  def get_token(config) do
    ExSwift.Auth.Cache.get(config)
  end
end
