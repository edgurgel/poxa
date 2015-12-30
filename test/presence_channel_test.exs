defmodule Poxa.PresenceChannelTest do
  use ExUnit.Case
  import SpawnHelper
  import Poxa.PresenceChannel

  test "return unique user ids currently subscribed" do
    register_to_channel("other_app_id", "presence-channel-test", {:other_user_id, :other_user_info})
    register_to_channel("app_id", "presence-channel-test", {:user_id, :user_info})
    spawn_registered_process("app_id", "presence-channel-test", {:user_id, :user_info})
    spawn_registered_process("app_id", "presence-channel-test", {:user_id2, :user_info2})

    assert users("presence-channel-test", "app_id") == [:user_id, :user_id2]
  end

  test "return number of unique subscribed users" do
    register_to_channel("other_app_id", "presence-channel-test2", {:other_user_id, :other_user_info})
    register_to_channel("app_id", "presence-channel-test2", {:user_id, :user_info})
    spawn_registered_process("app_id", "presence-channel-test2", {:user_id2, :user_info2})

    assert user_count("presence-channel-test2", "app_id") == 2
  end
end
