defmodule Poxa.Registry do
  alias Poxa.PresenceSubscription

  @doc """
  Childspec
  """
  @callback child_spec(options :: keyword()) :: Supervisor.child_spec()

  @doc """
  Registers a property for the current process.
  """
  @callback register!(binary) :: :ok | {:error, any}

  @doc """
  Registers a property for the current process with a given map value.
  """
  @callback register!(binary, map) :: :ok | {:error, any}

  @doc """
  Unregisters a property for the current process.
  """
  @callback unregister!(binary) :: :ok | {:error, any}

  @doc """
  Sends a message to a channel and identify it as coming from the given sender.
  """
  @callback send!(message :: binary, channel :: binary, pid) :: any

  @doc """
  Sends a message to a channel and identify it as coming from the given sender
  through a specific socket_id.
  """
  @callback send!(message :: binary, channel :: binary, pid, binary) :: any

  @doc """
  Returns the subscription count of a channel. If a connection identifier is provided,
  it counts only the subscriptions identified by the given identifier.
  """
  @callback subscription_count(any, PresenceSubscription.user_id() | pid) :: non_neg_integer

  @callback subscription_count(any) :: non_neg_integer

  @doc """
  Returns the presence channel subscriptions of the given process.
  """
  @callback presence_subscriptions(pid) :: [{String.t(), PresenceSubscription.user_id()}]

  @doc """
  Returns the list of channels that have at least one subscription
  """
  @callback channels() :: list(binary())

  @doc """
  Returns the unique subscriptions of the given channel.
  """
  @callback unique_subscriptions(binary) :: %{
              PresenceSubscription.user_id() => PresenceSubscription.user_info()
            }

  @doc """
  Returns the value assigned with the given property.
  """
  @callback fetch(binary) :: map

  @doc """
  Cleans up the registry data.
  """
  @callback clean_up() :: any

  @optional_callbacks child_spec: 1

  def adapter do
    case Application.get_env(:poxa, :registry_adapter) do
      "gproc" -> Poxa.Adapter.GProc
      "phoenix_pubsub" -> Poxa.Adapter.PhoenixPubSub
      nil -> raise "adapter not configured"
      adapter -> raise "adapter '#{adapter}' not found"
    end
  end
end
