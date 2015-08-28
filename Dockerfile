FROM ubuntu:trusty

ENV DEBIAN_FRONTEND noninteractive

# Essential packages
RUN apt-get -y update && \
    apt-get -y install wget locales build-essential git

# Ensure locale
RUN apt-get -y update
RUN dpkg-reconfigure locales && \
    locale-gen en_US.UTF-8 && \
    /usr/sbin/update-locale LANG=en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# Install Erlang and Elixir
RUN mkdir /tmp/erlang-build
WORKDIR /tmp/erlang-build
RUN wget http://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb
RUN dpkg -i erlang-solutions_1.0_all.deb
RUN apt-get -y update && \
    apt-get -y install erlang elixir

# Clean Up
WORKDIR /
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY . /src

ENV MIX_ENV prod
ENV PORT 8080
EXPOSE $PORT

WORKDIR /src/
RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix do deps.get, compile, compile.protocols

CMD ["mix", "run", "--no-halt"]
