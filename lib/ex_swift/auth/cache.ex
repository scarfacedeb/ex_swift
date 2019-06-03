defmodule ExSwift.Auth.Cache do
  @moduledoc """
  ETS cache to store authenticated tokens.
  """

  use GenServer

  @ets_opts [:named_table, read_concurrency: true]

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def get(config) do
    case :ets.lookup(__MODULE__, :token) do
      [{:token, token}] -> token
      [] -> GenServer.call(__MODULE__, {:refresh_config, config}, 30_000)
    end
  end

  ## Callbacks

  def init(:ok) do
    ets = :ets.new(__MODULE__, @ets_opts)
    {:ok, ets}
  end

  def handle_call({:refresh_config, config}, _from, ets) do
    token = refresh_config(config, ets)
    {:reply, token, ets}
  end

  def handle_info({:refresh_config, config}, ets) do
    refresh_config(config, ets)
    {:noreply, ets}
  end

  def refresh_config(config, ets) do
    token = ExSwift.Auth.Token.create(config)
    :ets.insert(ets, {:token, token})
    Process.send_after(self(), {:refresh_config, config}, refresh_in(token.expires_at))
    token
  end

  def refresh_in(expires_at) do
    expires_at_secs = expires_at |> DateTime.to_unix()
    now_secs = DateTime.utc_now() |> DateTime.to_unix()

    time_to_expiration = expires_at_secs - now_secs
    # check five mins prior to expiration
    refresh_in = time_to_expiration - 5 * 60
    # check now if we should have checked in the past
    max(0, refresh_in * 1000)
  end
end
