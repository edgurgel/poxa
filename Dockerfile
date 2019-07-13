# Based on https://github.com/hexpm/hexpm/blob/08e80ed4fe82b145f6cee1d01da16e162add2a56/Dockerfile
FROM elixir:1.9.0-alpine as build

ENV MIX_ENV=prod

RUN mkdir /app
WORKDIR /app

RUN mix local.hex --force && mix local.rebar --force

# install mix dependencies
COPY mix.exs mix.lock ./
COPY config config
RUN mix deps.get
RUN mix deps.compile

# build project
COPY priv priv
COPY lib lib
RUN mix compile

# build release
COPY rel rel
RUN mix release

# prepare release image
FROM alpine:3.9 AS app
RUN apk add --update bash openssl

RUN mkdir /app
WORKDIR /app

COPY --from=build /app/_build/prod/rel/poxa ./
RUN chown -R nobody: /app
USER nobody

ENV HOME=/app
CMD /app/bin/poxa start
