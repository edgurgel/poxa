defmodule Poxa.AuthorizationHelper do
  @moduledoc """
  This module providers a helper macro used for authentication in api handlers.
  """

  alias Poxa.Authentication

  @doc """
  Takes the Request from Cowboy and verifys the signature using the Authentication module.
  """
  @spec is_authorized(:cowboy_req.req, any) :: {true, :cowboy_req.req, any} | {{false, binary}, :cowboy_req.req, nil}
  def is_authorized(req, state) do
    {:ok, body, req} = :cowboy_req.body(req)
    {method, req} = :cowboy_req.method(req)
    {qs_vals, req} = :cowboy_req.qs_vals(req)
    {path, req} = :cowboy_req.path(req)
    if Authentication.check(method, path, body, qs_vals) do
      {true, req, state}
    else
      {{false, "authentication failed"}, req, nil}
    end
  end
end
