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

    # |> IO.inspect()

    {:ok, %{state | channels: channels}}
  end
end
