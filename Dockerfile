FROM elixir:1.5.2-alpine AS builder

ENV APP_NAME poxa
ENV MIX_ENV prod

RUN apk --no-cache add git erlang-xmerl erlang-crypto erlang-sasl

COPY . /source
WORKDIR /source

RUN mix local.hex --force && mix local.rebar --force
RUN mix deps.get
RUN mix compile
RUN echo "" > config/poxa.prod.conf
RUN mix release
RUN mkdir -p /app/$APP_NAME
WORKDIR /app/$APP_NAME
RUN tar xzf /source/_build/prod/rel/$APP_NAME/releases/0.7.1/$APP_NAME.tar.gz


FROM alpine:3.6

ENV APP_NAME poxa
ENV MIX_ENV prod

RUN apk --no-cache add bash openssl

COPY --from=builder /app /app

CMD /app/$APP_NAME/bin/$APP_NAME foreground
