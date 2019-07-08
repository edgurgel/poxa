defmodule Poxa.Registry do
  alias Poxa.PresenceSubscription

  @doc """
  Registers a property for the current process.
  """
  @callback register!(binary) :: any

  @doc """
  Registers a property for the current process with a given value.
  """
  @callback register!(binary, any) :: any

  @doc """
  Unregisters a property for the current process.
  """
  @callback unregister!(binary) :: any

  @doc """
  Sends a message to a channel and identify it as coming from the given sender.
  """
  @callback send!(binary, binary, PresenceSubscription.user_id() | pid) :: any

  @doc """
  Sends a message to a channel and identify it as coming from the given sender
  through a specific socket_id.
  """
  @callback send!(binary, binary, any, binary) :: any

  @doc """
  Returns the subscription count of a channel. If a connection identifier is provided,
  it counts only the subscriptions identified by the given identifier.
  """
  @callback subscription_count(binary, PresenceSubscription.user_id() | pid | :_) ::
              non_neg_integer

  @doc """
  Returns the presence channel subscriptions of the given process.
  """
  @callback subscriptions(pid) :: list()

  @doc """
  Returns the list of channels the `pid` is subscribed to.
  """
  @callback channels(pid) :: list(binary())

  @doc """
  Returns the unique subscriptions of the given channel.
  """
  @callback unique_subscriptions(binary) :: Map.t()

  @doc """
  Returns the value assigned with the given property.
  """
  @callback fetch(binary) :: any

  @doc """
  Cleans up the registry data.
  """
  @callback clean_up() :: any

  def adapter do
    case Application.get_env(:poxa, :registry_adapter) do
      "gproc" -> Poxa.Adapter.GProc
      nil -> raise "adapter not configured"
      adapter -> raise "adapter '#{adapter}' not found"
    end
  end
end
