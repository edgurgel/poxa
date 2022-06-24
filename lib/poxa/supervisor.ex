defmodule Poxa.Supervisor do
  use Supervisor

  @doc false
  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  @impl true
  @doc false
  def init([]) do
    {:ok, web_hook} = Application.fetch_env(:poxa, :web_hook)
    subscription_worker = Poxa.SubscriptionHandler

    children =
      if to_string(web_hook) != "" do
        web_wook_supervisor = Poxa.WebHook.Supervisor
        [subscription_worker, web_wook_supervisor]
      else
        [subscription_worker]
      end

    Poxa.Adapter.PhoenixPubSub.child_spec([])

    Supervisor.init(children ++ registry_child_spec(), strategy: :one_for_one)
  end

  # FIXME
  defp registry_child_spec() do
    if function_exported?(Poxa.registry(), :child_spec, 1) do
      [Poxa.registry().child_spec([])]
    else
      []
    end
  end
end
