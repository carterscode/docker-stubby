# Build stage.
FROM debian:bookworm-slim AS builder

ARG DEBIAN_FRONTEND=noninteractive
RUN \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get -y dist-upgrade && \
  apt-get install -y --no-install-recommends \
    autoconf \
    apt-utils \
    build-essential \
    g++ \
    ca-certificates \
    cmake \
    libgetdns-dev \
    libidn2-0-dev \
    libssl-dev \
    libunbound-dev \
    libyaml-dev \
  && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/

COPY . /usr/src/stubby/
WORKDIR /usr/src/stubby/
RUN echo $(ls /usr/src/stubby/)

RUN cd /usr/src/stubby/stubby && cmake .
RUN cd /usr/src/stubby/stubby && make

# Final image.
FROM debian:bookworm-slim

ARG DEBIAN_FRONTEND=noninteractive
RUN \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get -y dist-upgrade && \
  apt-get -y install \
    ca-certificates \
    libgetdns10 \
    libidn2-0 \
    libunbound8 \
    libyaml-0-2 \
    openssl \
  && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/

COPY --from=builder /usr/src/stubby/stubby /usr/local/bin
COPY --from=builder /usr/src/stubby/stubby/stubby.yml.example /usr/local/etc/stubby/stubby/stubby.yml

# Modify provided configuration file to listen on '0.0.0.0'. This is
# required for receiving incoming connections from outside the container.
RUN sed -i 's/^listen_addresses:/listen_addresses:\n  - 0.0.0.0/' \
    /usr/local/etc/stubby/stubby/stubby.yml
# Check if previous step succeeded (build will fail otherwise).
RUN grep --before-context 1 --after-context 3 '^  - 0.0.0.0$' \
    /usr/local/etc/stubby/stubby/stubby.yml

# Notice: since program is not catching TERM signal, it will be forcefully
# killed by Docker runtime on stop after timeout (see issue #188).
ENTRYPOINT [ "stubby" ]
