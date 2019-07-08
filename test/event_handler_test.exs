defmodule Poxa.EventHandlerTest do
  use ExUnit.Case
  alias Poxa.PusherEvent
  alias Poxa.Authentication
  alias Poxa.Event
  use Mimic
  import Poxa.EventHandler

  setup do
    stub(:cowboy_req)
    stub(Jason)
    stub(PusherEvent)
    :ok
  end

  describe "malformed_request/2" do
    test "valid data" do
      event = %PusherEvent{}
      expect(:cowboy_req, :read_body, fn :req -> {:ok, :body, :req1} end)
      expect(Jason, :decode, fn :body -> {:ok, :data} end)
      expect(PusherEvent, :build, fn :data -> {:ok, event} end)

      assert malformed_request(:req, :state) == {false, :req1, %{body: :body, event: event}}
    end

    test "invalid JSON" do
      expect(:cowboy_req, :read_body, fn :req -> {:ok, :body, :req1} end)
      expect(Jason, :decode, fn :body -> :error end)
      expect(:cowboy_req, :set_resp_body, fn _, _ -> :req2 end)

      assert malformed_request(:req, :state) == {true, :req2, :state}
    end

    test "invalid data" do
      expect(:cowboy_req, :read_body, fn :req -> {:ok, :body, :req1} end)
      expect(Jason, :decode, fn :body -> {:ok, :data} end)
      expect(PusherEvent, :build, fn :data -> {:error, :reason} end)
      expect(:cowboy_req, :set_resp_body, fn _, _ -> :req2 end)

      assert malformed_request(:req, :state) == {true, :req2, :state}
    end
  end

  describe "is_authorized/2" do
    test "failing authentication" do
      expect(:cowboy_req, :parse_qs, fn :req -> :qsvals end)
      expect(:cowboy_req, :method, fn :req -> :method end)
      expect(:cowboy_req, :path, fn :req -> :path end)
      expect(Authentication, :check, fn _, _, _, _ -> false end)
      expect(:cowboy_req, :set_resp_body, fn _, :req -> :req2 end)

      assert is_authorized(:req, %{body: :body}) ==
               {{false, "Authentication error"}, :req2, %{body: :body}}
    end

    test "correct authentication" do
      expect(Authentication, :check, fn _, _, _, _ -> true end)
      expect(:cowboy_req, :parse_qs, fn :req -> :qsvals end)
      expect(:cowboy_req, :method, fn :req -> :method end)
      expect(:cowboy_req, :path, fn :req -> :path end)

      assert is_authorized(:req, %{body: :body}) == {true, :req, %{body: :body}}
    end
  end

  describe "valid_entity_length/2" do
    test "valid_entity_length with data key smaller than 10KB" do
      event = %PusherEvent{data: "not10KB"}
      assert valid_entity_length(:req, %{event: event}) == {true, :req, %{event: event}}
    end

    test "valid_entity_length with data key bigger than 10KB" do
      data = File.read!("test/more_than_10KB.data")
      event = %PusherEvent{data: data}
      expect(Jason, :encode!, & &1)

      expect(:cowboy_req, :set_resp_body, fn %{error: "Data key must be smaller than 10000B"},
                                             :req ->
        :req2
      end)

      assert valid_entity_length(:req, %{event: event}) == {false, :req2, %{event: event}}
    end
  end

  describe "post/2" do
    test "post event" do
      event = %PusherEvent{}
      expect(PusherEvent, :publish, fn ^event -> :ok end)
      expect(Event, :notify, fn _, _ -> :ok end)
      expect(:cowboy_req, :set_resp_body, fn _, :req -> :req2 end)

      assert post(:req, %{event: event}) == {true, :req2, nil}
    end
  end
end
