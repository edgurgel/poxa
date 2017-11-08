FROM elixir:1.5.2-alpine

ENV APP_NAME poxa
ENV MIX_ENV prod

RUN apk --update add bash git erlang-xmerl erlang-crypto erlang-sasl && rm -rf /var/cache/apk/*

COPY . /source
WORKDIR /source

RUN mix local.hex --force && mix local.rebar --force
RUN mix deps.get
RUN mix compile
RUN echo "" > config/poxa.prod.conf
RUN mix release

RUN mkdir /app && cp -r _build/prod/rel/$APP_NAME /app && rm -rf /source

CMD /app/$APP_NAME/bin/$APP_NAME foreground
