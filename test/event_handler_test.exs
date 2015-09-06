defmodule Poxa.EventHandlerTest do
  use ExUnit.Case
  alias Poxa.PusherEvent
  alias Poxa.Authentication
  alias Poxa.Event
  import :meck
  import Poxa.EventHandler

  setup do
    on_exit fn -> unload end
    :ok
  end

  test "malformed_request with valid data" do
    event = %PusherEvent{}
    expect(:cowboy_req, :body, 1, {:ok, :body, :req1})
    expect(:cowboy_req, :binding, 2, {"app_id", :req2})
    expect(JSX, :decode, 1, {:ok, :data})
    expect(PusherEvent, :build, [{["app_id", :data], {:ok, event}}])

    assert malformed_request(:req, :state) == {false, :req2, %{body: :body, event: event}}

    assert validate :cowboy_req
    assert validate JSX
  end

  test "malformed_request with invalid JSON" do
    expect(:cowboy_req, :body, 1, {:ok, :body, :req1})
    expect(:cowboy_req, :set_resp_body, 2, :req2)
    expect(JSX, :decode, 1, :error)

    assert malformed_request(:req, :state) == {true, :req2, :state}

    assert validate :cowboy_req
    assert validate JSX
  end

  test "malformed_request with invalid data" do
    expect(:cowboy_req, :body, 1, {:ok, :body, :req1})
    expect(:cowboy_req, :binding, 2, {"app_id", :req2})
    expect(:cowboy_req, :set_resp_body, 2, :req3)
    expect(JSX, :decode, 1, {:ok, :data})
    expect(PusherEvent, :build, [{["app_id", :data], {:error, :reason}}])

    assert malformed_request(:req, :state) == {true, :req3, :state}

    assert validate :cowboy_req
    assert validate JSX
  end

  test "is_authorized with failing authentication" do
    expect(Authentication, :check, 5, false)
    expect(:cowboy_req, :qs_vals, 1, {:qsvals, :req1})
    expect(:cowboy_req, :method, 1, {:method, :req2})
    expect(:cowboy_req, :path, 1, {:path, :req3})
    expect(:cowboy_req, :binding, [{[:app_id, :req3], {:app_id, :req4}}])
    expect(:cowboy_req, :set_resp_body, 2, :req5)

    assert is_authorized(:req, %{body: :body}) == {false, :req5, %{body: :body}}

    assert validate Authentication
    assert validate :cowboy_req
  end

  test "is_authorized with correct authentication" do
    expect(Authentication, :check, 5, true)
    expect(:cowboy_req, :qs_vals, 1, {:qsvals, :req2})
    expect(:cowboy_req, :method, 1, {:method, :req3})
    expect(:cowboy_req, :path, 1, {:path, :req3})
    expect(:cowboy_req, :binding, [{[:app_id, :req3], {:app_id, :req4}}])

    assert is_authorized(:req, %{body: :body}) == {true, :req4, %{body: :body}}

    assert validate Authentication
    assert validate :cowboy_req
  end

  test "valid_entity_length with data key smaller than 10KB" do
    event = %PusherEvent{data: "not10KB"}
    assert valid_entity_length(:req, %{event: event}) == {true, :req, %{event: event}}
  end

  test "valid_entity_length with data key bigger than 10KB" do
    data = File.read! "test/more_than_10KB.data"
    event = %PusherEvent{data: data}
    expect(:cowboy_req, :set_resp_body, 2, :req2)

    assert valid_entity_length(:req, %{event: event}) == {false, :req2, %{event: event}}

    assert validate :cowboy_req
  end

  test "post event" do
    event = %PusherEvent{}
    expect(PusherEvent, :publish, [{[event], :ok}])
    expect(Event, :notify, 2, :ok)
    expect(:cowboy_req, :set_resp_body, 2, :req2)

    assert post(:req, %{event: event}) == {true, :req2, nil}

    assert validate PusherEvent
    assert validate :cowboy_req
    assert validate Event
  end
end
