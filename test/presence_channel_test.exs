defmodule Poxa.PresenceChannelTest do
  use ExUnit.Case
  import SpawnHelper
  import Poxa.PresenceChannel

  test "return unique user ids currently subscribed" do
    register_to_channel("presence-channel", {:user_id, :user_info})
    spawn_registered_process("presence-channel", {:user_id, :user_info})
    spawn_registered_process("presence-channel", {:user_id2, :user_info2})

    assert users("presence-channel") == [:user_id, :user_id2]
  end

  test "return number of unique subscribed users" do
    register_to_channel("presence-channel", {:user_id, :user_info})
    spawn_registered_process("presence-channel", {:user_id2, :user_info2})

    assert user_count("presence-channel") == 2
  end
end
