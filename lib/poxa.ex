defmodule Poxa do
  @moduledoc """
  This application is a server that understands the Pusher Protocol
  More info at: http://pusher.com/docs/pusher_protocol
  """
  use Application.Behaviour
  require Lager

  def start(_type, _args) do
    dispatch = :cowboy_router.compile([
      {:_, [ { '/ping', Poxa.PingHandler, [] },
             { '/apps/:app_id/events', Poxa.EventHandler, [] },
             { '/apps/:app_id/channels[/:channel_name]', Poxa.ChannelsHandler, [] },
             { '/apps/:app_id/channels/:channel_name/users', Poxa.UsersHandler, [] },
             { '/app/:app_key', Poxa.WebsocketHandler, [] } ] }
    ])
    case load_config do
      {:ok, config} ->
        Lager.info 'Starting Poxa using app_key: ~p, app_id: ~p, app_secret: ~p on port ~p', config
        port = List.last(config)
        {:ok, _} = :cowboy.start_http(:http, 100,
                                      [port: port],
                                      [env: [dispatch: dispatch]])
        run_ssl(dispatch)
        Poxa.Supervisor.start_link
      :invalid_configuration ->
        Lager.error "Error on start, set app_key, app_id and app_secret"
        exit(:invalid_configuration)
    end

  end

  def stop(_State), do: :ok

  defp load_config do
    try do
      {:ok, app_key} = :application.get_env(:poxa, :app_key)
      {:ok, app_id} = :application.get_env(:poxa, :app_id)
      {:ok, app_secret} = :application.get_env(:poxa, :app_secret)
      {:ok, port} = :application.get_env(:poxa, :port)
      {:ok, [app_key, app_id, app_secret, port]}
    rescue
      MatchError -> :invalid_configuration
    end
  end

  defp run_ssl(dispatch) do
    case :application.get_env(:poxa, :ssl) do
      {:ok, ssl_config} ->
        if Enum.all?([:port, :cacertfile, :certfile, :keyfile], &Keyword.has_key?(ssl_config, &1)) do
          {:ok, _} = :cowboy.start_https(:https, 100,
                                         ssl_config,
                                         [env: [dispatch: dispatch] ])
          ssl_port = Keyword.get(ssl_config, :port)
          Lager.info "Starting Poxa using SSL on port #{ssl_port}"
        else
          Lager.error "Please specify port, cacertfile, certfile and keyfile"
        end
      :undefined -> Lager.info "SSL not configured/started"
    end
  end

end
