defmodule Poxa.EventHandlerTest do
  use ExUnit.Case
  alias Poxa.PusherEvent
  alias Poxa.Authentication
  alias Poxa.Event
  import Mimic
  import Poxa.EventHandler

  setup :verify_on_exit!

  setup do
    stub(:cowboy_req)
    stub(Poison)
    stub(PusherEvent)
    :ok
  end

  test "malformed_request with valid data" do
    event = %PusherEvent{}
    expect(:cowboy_req, :body, fn :req -> {:ok, :body, :req1} end)
    expect(Poison, :decode, fn :body -> {:ok, :data} end)
    expect(PusherEvent, :build, fn :data -> {:ok, event} end)

    assert malformed_request(:req, :state) == {false, :req1, %{body: :body, event: event}}
  end

  test "malformed_request with invalid JSON" do
    expect(:cowboy_req, :body, fn :req -> {:ok, :body, :req1} end)
    expect(Poison, :decode, fn :body -> :error end)
    expect(:cowboy_req, :set_resp_body, fn _, _ -> :req2 end)

    assert malformed_request(:req, :state) == {true, :req2, :state}
  end

  test "malformed_request with invalid data" do
    expect(:cowboy_req, :body, fn :req -> {:ok, :body, :req1} end)
    expect(Poison, :decode, fn :body -> {:ok, :data} end)
    expect(PusherEvent, :build, fn :data -> {:error, :reason} end)
    expect(:cowboy_req, :set_resp_body, fn _, _ -> :req2 end)

    assert malformed_request(:req, :state) == {true, :req2, :state}
  end

  test "is_authorized with failing authentication" do
    expect(:cowboy_req, :qs_vals, fn :req -> {:qsvals, :req2} end)
    expect(:cowboy_req, :method, fn :req2 -> {:method, :req3} end)
    expect(:cowboy_req, :path, fn :req3 -> {:path, :req4} end)
    expect(Authentication, :check, fn _, _, _, _ -> false end)
    expect(:cowboy_req, :set_resp_body, fn _, :req4 -> :req5 end)

    assert is_authorized(:req, %{body: :body}) == {{false, "Authentication error"}, :req5, %{body: :body}}
  end

  test "is_authorized with correct authentication" do
    expect(Authentication, :check, fn _, _, _, _ -> true end)
    expect(:cowboy_req, :qs_vals, fn :req -> {:qsvals, :req2} end)
    expect(:cowboy_req, :method, fn :req2 -> {:method, :req3} end)
    expect(:cowboy_req, :path, fn :req3 -> {:path, :req4} end)

    assert is_authorized(:req, %{body: :body}) == {true, :req4, %{body: :body}}
  end

  test "valid_entity_length with data key smaller than 10KB" do
    event = %PusherEvent{data: "not10KB"}
    assert valid_entity_length(:req, %{event: event}) == {true, :req, %{event: event}}
  end

  test "valid_entity_length with data key bigger than 10KB" do
    data = File.read! "test/more_than_10KB.data"
    event = %PusherEvent{data: data}
    expect(:cowboy_req, :set_resp_body, fn _, :req -> :req2 end)

    assert valid_entity_length(:req, %{event: event}) == {false, :req2, %{event: event}}
  end

  test "post event" do
    event = %PusherEvent{}
    expect(PusherEvent, :publish, fn ^event -> :ok end)
    expect(Event, :notify, fn _, _ -> :ok end)
    expect(:cowboy_req, :set_resp_body, fn _, :req -> :req2 end)

    assert post(:req, %{event: event}) == {true, :req2, nil}
  end
end
