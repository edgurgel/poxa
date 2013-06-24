[![Build Status](https://travis-ci.org/edgurgel/poxa.png?branch=master)](https://travis-ci.org/edgurgel/poxa)
# Poxa

Open Pusher implementation compatible with Pusher libraries. It's designed to be used as a single registered app with id, secret and key defined on start.

## Features

* Public channels;
* Private channels;
* Presence channels;
* Client events;
* SSL on websocket and REST api;

## TODO

* Complete REST api;
* Mimic pusher error codes;
* Simple console;
* Integration test using pusher-js or other client library;
* Web hooks;
* Specify types signature to functions and use dyalizer to check them;

## Typical usage

Poxa is a standalone elixir server implementation of the Pusher protocol.

You need [Elixir](http://elixir-lang.org) 0.9.3 at least and Erlang R16B.

Clone this repository

Run

```console
mix deps.get
mix compile
```
The default configuration is:

* Port: 8080
* App id: 'app_id'
* App key: 'app_key'
* App secret: 'secret'

You can run and configure these values using this command:

```console
elixir --erl "-poxa port 9090 -poxa app_id '<<"12345">>' -poxa app_key '<<"key-12345">>' -poxa app_secret '<<"secret6789">>'" -S mix run --no-halt
```

Or you can setup a configuration file like this:

test.config

```elixir
[{poxa, [{port, 8080},
         {app_id, <<"12345">>},
         {app_key, <<"key-12345">>},
         {app_secret, <<"secret6789">>}]}].
```

And run:

```console
elixir --erl "-config test" -S mix run --no-halt
```

And if you want SSL, try something like this on your configuration file:

```elixir
[{poxa, [{port, 8080},
         {app_id, <<"app_id">>},
         {app_key, <<"app_key">>},
         {app_secret, <<"secret">>},
         {ssl, [{port, 8443},
                {cacertfile, "priv/ssl/server-ca.crt"},
                {certfile, "priv/ssl/server.crt"},
                {keyfile, "priv/ssl/server.key"}]}]}].
```

## Release

If you just want to run an executable, follow these instructions:

TODO

## Your application

If you are using the pusher-gem:

```ruby
Pusher.host   = 'localhost'
Pusher.port   = 8080
```
And pusher-js:
```javascript
Pusher.host    = 'localhost'
Pusher.ws_port = 8080
```

## Implementation

Poxa uses [gproc](https://github.com/uwiger/gproc) extensively to register websocket connections as channels. So, when a client subscribes for channel 'example-channel', the websocket connection (which is a elixir process) is "tagged" as **{pusher, example-channel}**. When a pusher event is triggered on the 'example-channel', every websocket matching the tag receives the event.

## Contributing

If you'd like to hack on Poxa, start by forking my repo on Github.

Dependencies can be fetched running:

```console
MIX_ENV=dev mix deps.get
```

Compile:

```console
mix compile
```

The test suite used is the ExUnit and [meck](http://github.com/eproxus/meck) to mock stuff. You can run the tests:

```console
mix test
```

Pull requests are greatly appreciated.

## Pusher

Pusher is an excellent service and you should use it on production.


