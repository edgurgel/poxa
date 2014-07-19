defmodule Poxa.AuthorizationHelper do
  alias Poxa.Authentication

  @spec is_authorized(:cowboy_req.req, any) :: {true, :cowboy_req.req, any} | {{false, binary}, :cowboy_req.req, nil}
  def is_authorized(req, state) do
    {:ok, body, req} = :cowboy_req.body(req)
    {method, req} = :cowboy_req.method(req)
    {qs_vals, req} = :cowboy_req.qs_vals(req)
    {path, req} = :cowboy_req.path(req)
    auth = Authentication.check(method, path, body, qs_vals)
    if auth == :ok do
      {true, req, state}
    else
      {{false, "authentication failed"}, req, nil}
    end
  end
end
