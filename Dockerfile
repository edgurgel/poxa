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


FROM elixir:1.5.2-alpine

ENV APP_NAME poxa
ENV MIX_ENV prod

RUN apk --no-cache add bash erlang-xmerl erlang-crypto erlang-sasl

COPY --from=builder /source/_build/prod/rel /app

CMD /app/$APP_NAME/bin/$APP_NAME foreground
