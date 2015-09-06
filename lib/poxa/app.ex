defmodule Poxa.App do
  use GenServer

  @doc """
  Given the app_key it returns the related app_id
  """
  def id(key) do
    case :ets.match(Poxa.App, {:'$1', key, :'_'}) do
      [[id]] -> {:ok, id}
      _ -> {:error, {:key_not_found, key}}
    end
  end

  @doc """
  Given the app_id it returns the related app_key
  """
  @spec key(binary) :: {:ok, binary} | {:error, term}
  def key(id) do
    case :ets.lookup(Poxa.App, id) do
      [{^id, key, _}] -> {:ok, key}
      _ -> {:error, {:id_not_found, id}}
    end
  end

  @doc """
  Given the app_key it returns the related app_secret
  """
  def secret(key) do
    case :ets.match(Poxa.App, {:'_', key, :'$1'}) do
      [[secret]] -> {:ok, secret}
      _ -> {:error, {:key_not_found, key}}
    end
  end

  @doc """
  Given the app_id it returns the related app_key and secret
  """
  def key_secret(id) do
    case :ets.lookup(Poxa.App, id) do
      [{^id, key, secret}] -> {:ok, {key, secret}}
      _ -> {:error, {:id_not_found, id}}
    end
  end

  @doc """
  Reload table content using Application environment
  """
  @spec reload :: :ok
  def reload do
    GenServer.call(Poxa.App, :reload)
  end

  @doc false
  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, [name: Poxa.App])
  end

  @doc """
  Create ETS table to fetch app_id, app_key and secret
  """
  def init(_) do
    ets_options = [:ordered_set, :named_table, :protected, { :read_concurrency, true }]
    :ets.new(Poxa.App, ets_options)
    populate_table
    { :ok, :ok }
  end

  def handle_call(:reload, _from, _) do
    populate_table
    {:reply, :ok, :ok}
  end

  defp populate_table do
    apps = Application.get_env(:poxa, :apps, [])
    app = fetch_standalone_app
    for {app_id, app_key, secret} <- [app | apps] do
      :ets.insert(Poxa.App, {app_id, app_key, secret})
    end
  end

  defp fetch_standalone_app do
    app_id = Application.get_env(:poxa, :app_id)
    app_key = Application.get_env(:poxa, :app_key)
    app_secret = Application.get_env(:poxa, :app_secret)
    if app_id && app_key && app_secret do
      {app_id, app_key, app_secret}
    end
  end
end
