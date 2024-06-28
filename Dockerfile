# Based on https://github.com/hexpm/hexpm/blob/08e80ed4fe82b145f6cee1d01da16e162add2a56/Dockerfile
FROM docker.io/hexpm/elixir:1.17.1-erlang-26.2.5.1-alpine-3.17.8 as build

ENV MIX_ENV=prod

RUN mkdir /app
WORKDIR /app

RUN mix local.hex --force && mix local.rebar --force

# install mix dependencies
COPY mix.exs mix.lock ./
COPY config/config.exs config/
RUN mix deps.get --only $MIX_ENV
RUN mix deps.compile

# build project
COPY priv priv
COPY lib lib
RUN mix compile

COPY config/runtime.exs config/

# build release
COPY rel rel
RUN mix release

# prepare release image
FROM docker.io/library/alpine:3.17.8 AS app
RUN apk add --no-cache --update bash openssl ncurses-libs libstdc++

RUN mkdir /app
WORKDIR /app

COPY --from=build /app/_build/prod/rel/poxa ./
RUN chown -R nobody: /app
USER nobody

ENV HOME=/app
CMD /app/bin/poxa start
