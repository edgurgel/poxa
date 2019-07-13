defmodule Poxa.Supervisor do
  use Supervisor

  @doc false
  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  @doc false
  def init([]) do
    {:ok, web_hook} = Application.fetch_env(:poxa, :web_hook)
    subscription_worker = worker(Poxa.SubscriptionHandler, [])

    children =
      if to_string(web_hook) != "" do
        web_wook_supervisor = worker(Poxa.WebHook.Supervisor, [])
        [subscription_worker, web_wook_supervisor]
      else
        [subscription_worker]
      end

    supervise(children, strategy: :one_for_one)
  end
end
