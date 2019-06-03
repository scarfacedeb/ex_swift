defmodule ExSwift.Application do
  @moduledoc """

  """

  use Application

  @doc false
  @impl Application
  def start(_type, _args) do
    children = [
      {ExSwift.Auth.Cache, [name: ExSwift.Auth.Cache]}
    ]

    opts = [strategy: :one_for_one, name: ExSwift.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
