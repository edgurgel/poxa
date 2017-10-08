defmodule Poxa.EventHandlerTest do
  use ExUnit.Case
  alias Poxa.PusherEvent
  alias Poxa.Authentication
  alias Poxa.Event
  import :meck
  import Poxa.EventHandler

  setup do
    on_exit fn -> unload() end
    :ok
  end

  test "malformed_request with valid data" do
    event = %PusherEvent{}
    expect(:cowboy_req, :body, 1, {:ok, :body, :req1})
    expect(Poison, :decode, 1, {:ok, :data})
    expect(PusherEvent, :build, [{[:data], {:ok, event}}])

    assert malformed_request(:req, :state) == {false, :req1, %{body: :body, event: event}}

    assert validate :cowboy_req
    assert validate Poison
  end

  test "malformed_request with invalid JSON" do
    expect(:cowboy_req, :body, 1, {:ok, :body, :req1})
    expect(:cowboy_req, :set_resp_body, 2, :req2)
    expect(Poison, :decode, 1, :error)

    assert malformed_request(:req, :state) == {true, :req2, :state}

    assert validate :cowboy_req
    assert validate Poison
  end

  test "malformed_request with invalid data" do
    expect(:cowboy_req, :body, 1, {:ok, :body, :req1})
    expect(:cowboy_req, :set_resp_body, 2, :req2)
    expect(Poison, :decode, 1, {:ok, :data})
    expect(PusherEvent, :build, [{[:data], {:error, :reason}}])

    assert malformed_request(:req, :state) == {true, :req2, :state}

    assert validate :cowboy_req
    assert validate Poison
  end

  test "is_authorized with failing authentication" do
    expect(Authentication, :check, 4, false)
    expect(:cowboy_req, :qs_vals, 1, {:qsvals, :req2})
    expect(:cowboy_req, :method, 1, {:method, :req3})
    expect(:cowboy_req, :path, 1, {:path, :req3})
    expect(:cowboy_req, :set_resp_body, 2, :req4)

    assert is_authorized(:req, %{body: :body}) == {false, :req4, %{body: :body}}

    assert validate Authentication
    assert validate :cowboy_req
  end

  test "is_authorized with correct authentication" do
    expect(Authentication, :check, 4, true)
    expect(:cowboy_req, :qs_vals, 1, {:qsvals, :req2})
    expect(:cowboy_req, :method, 1, {:method, :req3})
    expect(:cowboy_req, :path, 1, {:path, :req3})

    assert is_authorized(:req, %{body: :body}) == {true, :req3, %{body: :body}}

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
