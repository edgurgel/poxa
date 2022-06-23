defmodule Poxa.Adapter.PhoenixPubSub.Tracker do
  use Phoenix.Tracker

  def start_link(opts) do
    opts = Keyword.merge([name: __MODULE__], opts)
    Phoenix.Tracker.start_link(__MODULE__, opts, opts)
  end

  @impl true
  def init(opts) do
    server = Keyword.fetch!(opts, :pubsub_server)

    {:ok,
     %{
       pubsub_server: server,
       node_name: Phoenix.PubSub.node_name(server),
       channels: %{}
     }}
  end

  @impl true
  def handle_diff(diff, state) do
    channels =
      Enum.reduce(diff, state.channels, fn
        {"pusher:" <> topic, {joins, leaves}}, acc ->
          update_in(acc, [topic], &((&1 || 0) + length(joins) - length(leaves)))

        _, acc ->
          acc
      end)
      |> IO.inspect()

    # for {"pusher:" <> topic, {joins, leaves}} <- diff do
    # for {key, meta} <- joins do
    # IO.puts("#{topic} - presence join: key \"#{key}\" with meta #{inspect(meta)}")
    # # msg = {:join, key, meta}
    # # Phoenix.PubSub.direct_broadcast!(state.node_name, state.pubsub_server, topic, msg)
    # end

    # for {key, meta} <- leaves do
    # IO.puts("#{topic} - presence leave: key \"#{key}\" with meta #{inspect(meta)}")
    # # msg = {:leave, key, meta}
    # # Phoenix.PubSub.direct_broadcast!(state.node_name, state.pubsub_server, topic, msg)
    # end
    # end

    {:ok, %{state | channels: channels}}
  end
end
