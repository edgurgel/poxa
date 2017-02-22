[![Build Status](https://travis-ci.org/edgurgel/poxa.svg?branch=master)](https://travis-ci.org/edgurgel/poxa)
[![Deps Status](https://beta.hexfaktor.org/badge/all/github/edgurgel/poxa.svg)](https://beta.hexfaktor.org/github/edgurgel/poxa)
[![Inline docs](http://inch-ci.org/github/edgurgel/poxa.svg?branch=master)](http://inch-ci.org/github/edgurgel/poxa)
[![Release](http://img.shields.io/github/release/edgurgel/poxa.svg)](https://github.com/edgurgel/poxa/releases/latest)
[![Deploy](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy)

# Poxa

Open Pusher implementation compatible with Pusher libraries. It's designed to be used as a single registered app with id, secret and key defined on start.

How do I speak 'poxa'?

['poʃa] - Phonetic notation

[posha] : po ( potion ), sha ( shall )

## Table of Contents

- [Features](#features)
- [TODO](#todo)
- [Typical usage](#typical-usage)
- [Release](#release)
- [Using Docker](#using-docker)
- [Your application](#your-application)
- [Console](#console)
- [Implementation](#implementation)
- [Contributing](#contributing)
- [Pusher](#pusher)
- [Acknowledgements](#acknowledgements)
- [Who is using it?](#who-is-using-it)

## Features

* Public channels;
* Private channels;
* Presence channels;
* Client events;
* SSL on websocket and REST API;
* Simple console;
* REST API
  * /users on presence channels
  * /channels/:channel_name
  * /channels

## TODO

* [ ] SockJS support;
* [x] Complete REST api;
* [x] Mimic pusher error codes;
* [x] Integration test using pusher-js or other client library;
* [x] Web hooks;
* [x] Add 'Vacated' and 'Occupied' events to Console;
* [X] Use GenEvent to generate Console events so other handlers can be attached (Web hook for example);
* [ ] Turn Poxa on a distributed server with multiple nodes;

## Typical usage

Poxa is a standalone elixir server implementation of the Pusher protocol.

You need [Elixir](http://elixir-lang.org) 1.2.6 at least and Erlang 18.0

Clone this repository

Run

```console
mix deps.get
mix compile
mix compile.protocols
```

The default configuration is:

* Port: 8080
* App id: 'app_id'
* App key: 'app_key'
* App secret: 'secret'

You can run and configure these values using these environment variables:

```
PORT=8080
POXA_APP_KEY=app_key
POXA_SECRET=secret
POXA_APP_ID=app_id
```

Or you can setup a configuration file like this:

my_config.exs

```elixir
use Mix.Config

config :poxa,
  port: 4567,
  app_key: "123456789",
  app_secret: "987654321",
  app_id: "theid"
```

And run:

```console
elixir -pa _build/dev/consolidated -S mix run --config my_config.exs --no-halt
```

And if you want SSL, try something like this on your configuration file:

```elixir
use Mix.Config

config :poxa,
  port: 4567,
  app_key: "123456789",
  app_secret: "987654321",
  app_id: "theid",
  ssl: [enabled: true,
        port: 8443,
        cacertfile: "priv/ssl/server-ca.crt",
        certfile: "priv/ssl/server.crt",
        keyfile: "priv/ssl/server.key"]
```

## Release

This is the preferred way to deploy a Poxa server.

If you just want to run a release, follow these instructions:

First download dependencies and generate the release

```console
MIX_ENV=prod mix do deps.get, compile, release
```

Then you can run it using:

```console
$ ./rel/poxa/bin/poxa
Usage: poxa {start|start_boot <file>|foreground|stop|restart|reboot|ping|rpc <m> <f> [<a>]|console|console_clean|console_boot <file>|attach|remote_console|upgrade}
```

To start as daemon you just need to:

```console
./rel/poxa/bin/poxa start
```

### Release configuration

Starting from Poxa 0.3.1 the configuration can be done on `./releases/0.3.1/poxa.conf` considering 0.3.1 is the release version.

You should see a file like this:

```
# HTTP port
poxa.port = 8080

# Pusher app key
poxa.app_key = "app_key"

# Pusher secret
poxa.app_secret = "secret"

# Pusher app id
poxa.app_id = "app_id"
```

You can change anything on this file and just start the release and this configuration will be used.

## Using Docker

Docker images are automatically built by [Docker Hub](https://hub.docker.com/r/edgurgel/poxa-automated/builds/). They are available at Docker Hub: https://hub.docker.com/r/edgurgel/poxa-automated/tags/

One can generate it just running `docker build -t local/poxa .`.

The docker run command should look like this:

```
docker run --rm -p 8080:8080 -v $PWD/mypoxa.conf:/app/poxa/running-config/poxa.conf local/poxa
```

## Your application

If you are using the pusher-gem:

```ruby
Pusher.host   = 'localhost'
Pusher.port   = 8080
```
And pusher-js:
```javascript

// will only use WebSockets
var pusher = new Pusher(APP_KEY, {
  wsHost: 'localhost',
  wsPort: 8080,
  enabledTransports: ["ws", "flash"],
  disabledTransports: ["flash"]
});
```

A working poxa is on http://poxa.herokuapp.com, with:

* App key: "app_key"
* App id: "app_id"
* App secret: "secret"
* Port: 80

Also a pusher example(https://github.com/pusher/pusher-presence-demo) is running using poxa at: http://poxa-presence-chat.herokuapp.com/

## Console

A simple console is available on index:

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

The test suite used is the ExUnit and [meck](http://github.com/eproxus/meck) to mock stuff.

To run tests:

```console
mix test
```

Pull requests are greatly appreciated.

## Pusher

Pusher is an excellent service and you should use it on production.

## Acknowledgements

Thanks to [@bastos](https://github.com/bastos) for the project name :heart:!

## Who is using it?

* [Waffle Takeout](https://takeout.waffle.io/)
* [Tinfoil Security](https://tinfoilsecurity.com/)
* Add your project/service here! Send a PR! :tada:
