[![Build Status](https://travis-ci.org/edgurgel/poxa.png?branch=master)](https://travis-ci.org/edgurgel/poxa)
[![Release](http://img.shields.io/github/release/edgurgel/poxa.svg)](https://github.com/edgurgel/poxa/releases/latest)

# Poxa 

Open Pusher implementation compatible with Pusher libraries. It's designed to be used as a single registered app with id, secret and key defined on start.

How do I speak 'poxa'? 

['poʃa] - Phonetic notation

[posha] : po ( potion ), sha ( shall )

## Table of Contents

- [Poxa ](#poxa-)
	- [Features](#features)
	- [TODO](#todo)
	- [Typical usage](#typical-usage)
	- [Release](#release)
	- [Your application](#your-application)
	- [Deploying on Heroku](#deploying-on-heroku)
	- [Console](#console)
	- [Implementation](#implementation)
	- [Contributing](#contributing)
	- [Pusher](#pusher)

**Table of Contents**  *generated with [DocToc](http://doctoc.herokuapp.com/)*

## Features

* Public channels;
* Private channels;
* Presence channels;
* Client events;
* SSL on websocket and REST API;
* Simple console;
* REST API
  * /users on presence channels
  * /channels/:channel_name (Partial support)
  * /channels (Partial support)

## TODO

* [ ] SockJS support;
* [ ] Complete REST api;
* [ ] Mimic pusher error codes;
* [ ] Integration test using pusher-js or other client library;
* [ ] Web hooks;
* [ ] Specify types signature to functions and use dialyzer to check them on Travis;
* [ ] Add 'Vacated' and 'Occupied' events to Console.

## Typical usage

Poxa is a standalone elixir server implementation of the Pusher protocol.

You need [Elixir](http://elixir-lang.org) 0.13.3 at least and Erlang 17.0

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

If you just want to run a release, follow these instructions:

First download dependencies and generate the release (or download it [here](https://github.com/edgurgel/poxa/releases))

```console
MIX_ENV=prod mix do deps.get, release
```

Then you can run it using:

```console
./rel/poxa/bin/poxa console
```

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

// will only use WebSockets
var pusher = new Pusher(API_KEY, {
  enabledTransports: ["ws", "flash"],
  disabledTransports: ["flash"]
});
```

## Deploying on Heroku

Add the file `Procfile`:

```
web: elixir --erl "-poxa port $PORT" -S mix run --no-halt
```

Add the file `elixir_buildpack.config`

```
# Erlang version
erlang_version=17.0

# Elixir version
elixir_version=0.13.2

# Do dependencies have to be built from scratch on every deploy?
always_build_deps=false
```

Configure the buildpack using:

```console
heroku config:set BUILDPACK_URL="https://github.com/HashNuke/heroku-buildpack-elixir.git"
```

And finally enable websocket on Heroku (for now it's on Heroku Labs)

```console
heroku labs:enable websockets
```

And this is it!

A working deploy is on http://poxa.herokuapp.com, with:

* App key: "app_key"
* App id: "app_id"
* App secret: "secret"
* Port: 80

Also a pusher example(https://github.com/pusher/pusher-presence-demo) is running using poxa at: http://poxa-presence-chat.herokuapp.com/

## Console

A simple console is avaiable on index:

![Console](http://i.imgur.com/zEbZZgN.png)

You can see it in action on http://poxa.herokuapp.com using "app_key" and "secret" to connect. Now open the [poxa-presence-chat](http://poxa-presence-chat.herokuapp.com) and watch events happening!

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

The test suite used is the ExUnit and [meck](http://github.com/eproxus/meck) to mock stuff. First download test dependencies:

```console
MIX_ENV=test mix deps.get
```


Now you can run the tests:

```console
mix test
```

Pull requests are greatly appreciated.

## Pusher

Pusher is an excellent service and you should use it on production.


