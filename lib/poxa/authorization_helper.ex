defmodule Poxa.AuthorizationHelper do
  @moduledoc """
  Helper to keep the cowboy rest is_authorized dry for Pusher authentication
  """

  @doc """
  A helper to share authentication process between handlers. It uses the cowboy `req` to retrieve the necessary data.
  """
  @spec is_authorized(:cowboy_req.req, any) :: {true, :cowboy_req.req, any} | {{false, binary}, :cowboy_req.req, nil}
  def is_authorized(req, state) do
    {:ok, body, req} = :cowboy_req.body(req)
    {method, req} = :cowboy_req.method(req)
    {qs_vals, req} = :cowboy_req.qs_vals(req)
    {path, req} = :cowboy_req.path(req)
    {app_id, req} = :cowboy_req.binding(:app_id, req)
    if Poxa.Authentication.check(app_id, method, path, body, qs_vals) do
      {true, req, state}
    else
      {{false, "authentication failed"}, req, nil}
    end
  end
end
