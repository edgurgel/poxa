[![Inline docs](http://inch-ci.org/github/edgurgel/poxa.svg?branch=master)](http://inch-ci.org/github/edgurgel/poxa)
[![Release](http://img.shields.io/github/release/edgurgel/poxa.svg)](https://github.com/edgurgel/poxa/releases/latest)
[![Docker](https://img.shields.io/docker/pulls/edgurgel/poxa-automated.svg)](https://hub.docker.com/r/edgurgel/poxa-automated)
# Poxa

Open Pusher implementation compatible with Pusher libraries. It's designed to be used as a single registered app with id, secret and key defined on start.

How do I speak 'poxa'?

['poʃa] - Phonetic notation

[posha] : po ( potion ), sha ( shall )

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

## Development

Poxa is a standalone elixir server implementation of the Pusher protocol.

You need [Elixir](http://elixir-lang.org) 1.16 at least and Erlang 26.0

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

## Using Docker

Docker images are automatically built by [Docker Hub](https://hub.docker.com/r/edgurgel/poxa-automated/builds/). They are available at Docker Hub: https://hub.docker.com/r/edgurgel/poxa-automated/tags/

One can generate it using: `docker build -t local/poxa .`.

The `docker run` command should look like this:

```
docker run --rm --name poxa -p 8080:8080 edgurgel/poxa-automated:latest
```

## Configuration

The following environment variables are supported:

* `PORT`
* `POXA_APP_KEY`
* `POXA_SECRET`
* `POXA_APP_ID`
* `POXA_REGISTRY_ADAPTER`
* `WEB_HOOK`
* `ACTIVITY_TIMEOUT`
* `POXA_SSL`
* `SSL_PORT`
* `SSL_CACERTFILE`
* `SSL_CERTFILE`
* `SSL_KEYFILE`

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

A working poxa is on https://poxa.onrender.com/, with:

* App key: "app_key"
* App id: "app_id"
* App secret: "secret"
* Port: 80

Also a pusher example(https://github.com/pusher/pusher-presence-demo) is running using poxa at: http://poxa-presence-chat.herokuapp.com/

## Console

A simple console is available on index:

![Console](http://i.imgur.com/zEbZZgN.png)

You can see it in action on [http://poxa.herokuapp.com](https://poxa.onrender.com/) using "app_key" and "secret" to connect. Now open the [poxa-presence-chat](http://poxa-presence-chat.herokuapp.com) and watch events happening!

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

The test suite used is the ExUnit and [Mimic](http://github.com/edgurgel/mimic) to mock stuff.

To run tests:

```console
mix test
```

Pull requests are greatly appreciated.

## TODO

* [ ] SockJS support;
* [x] Complete REST api;
* [x] Mimic pusher error codes;
* [x] Integration test using pusher-js or other client library;
* [x] Web hooks;
* [x] Add 'Vacated' and 'Occupied' events to Console;
* [X] Use `gproc` to generate Console events so other handlers can be attached (Web hook for example);
* [ ] Turn Poxa on a distributed server with multiple nodes;

## Pusher

Pusher is an excellent service and you should use it in production.

## Acknowledgements

Thanks to [@bastos](https://github.com/bastos) for the project name :heart:!

## Who is using it?

* [Waffle Takeout](https://takeout.waffle.io/)
* [Tinfoil Security](https://tinfoilsecurity.com/)
* Add your project/service here! Send a PR! :tada:
