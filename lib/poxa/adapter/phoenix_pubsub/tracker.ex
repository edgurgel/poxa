defmodule Poxa.Adapter.PhoenixPubSub.Tracker do
  use Phoenix.Tracker
  require Ex2ms

  @table :poxa_tracker_channels

  @doc """
  List all channels with at least 1 subscription
  """
  @spec channels :: [String.t()]
  def channels() do
    spec =
      Ex2ms.fun do
        {channel, count} -> channel
      end

    :ets.select(@table, spec)
  end

  @spec subscription_count(String.t()) :: non_neg_integer()
  def subscription_count(channel) do
    case :ets.lookup(@table, channel) do
      [] -> 0
      [{^channel, count}] -> count
    end
  end

  def start_link(opts) do
    opts = Keyword.merge([name: __MODULE__], opts)
    Phoenix.Tracker.start_link(__MODULE__, opts, opts)
  end

  @impl true
  def init(opts) do
    server = Keyword.fetch!(opts, :pubsub_server)
    :ets.new(@table, [:named_table, :protected])

    {:ok,
     %{
       pubsub_server: server,
       node_name: Phoenix.PubSub.node_name(server)
     }}
  end

  @impl true
  def handle_diff(diff, state) do
    Enum.each(diff, fn {"pusher:" <> channel, {joins, leaves}} ->
      value = length(joins) - length(leaves)
      result = :ets.update_counter(@table, channel, {2, value}, {channel, 0})

      # Keep the table clean of empty channels
      if result == 0, do: :ets.delete(@table, channel)
    end)

    {:ok, state}
  end
end
