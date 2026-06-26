# Multi-stage build for Dogecoin Core.
# The build context is the dogecoin/dogecoin source checked out at a release tag
# (see .github/workflows/build.yml), so `COPY . .` compiles the tagged source.

# ---- build stage ----
FROM debian:bookworm-slim AS build
ARG TARGETPLATFORM
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential libtool autotools-dev automake pkg-config bsdmainutils \
        python3 libssl-dev libevent-dev libboost-all-dev libdb5.3++-dev \
        ca-certificates git && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /dogecoin
COPY . .
RUN ./autogen.sh && \
    ./configure --disable-tests --disable-bench --with-gui=no \
                --with-incompatible-bdb && \
    make -j"$(nproc)" && \
    strip src/dogecoind src/dogecoin-cli src/dogecoin-tx

# ---- runtime stage ----
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
        libssl3 libevent-2.1-7 libevent-pthreads-2.1-7 libboost-system1.74.0 \
        libboost-filesystem1.74.0 libboost-thread1.74.0 libboost-chrono1.74.0 \
        libboost-program-options1.74.0 libdb5.3++ \
        ca-certificates gosu && \
    rm -rf /var/lib/apt/lists/* && \
    useradd -r -m -d /home/dogecoin dogecoin
COPY --from=build /dogecoin/src/dogecoind /dogecoin/src/dogecoin-cli /dogecoin/src/dogecoin-tx /usr/local/bin/
USER dogecoin
VOLUME ["/home/dogecoin/.dogecoin"]
EXPOSE 22555 22556
ENTRYPOINT ["dogecoind"]
CMD ["-printtoconsole"]
