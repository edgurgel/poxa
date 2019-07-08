defmodule Poxa.AuthorizationHelper do
  alias Poxa.Authentication

  @spec is_authorized(:cowboy_req.req(), any) ::
          {true, :cowboy_req.req(), any} | {{false, binary}, :cowboy_req.req(), nil}
  def is_authorized(req, state) do
    {:ok, body, req} = :cowboy_req.read_body(req)
    method = :cowboy_req.method(req)
    qs_vals = :cowboy_req.parse_qs(req)
    path = :cowboy_req.path(req)

    if Authentication.check(method, path, body, qs_vals) do
      {true, req, state}
    else
      {{false, "authentication failed"}, req, nil}
    end
  end
end
