#
# Dockerfile for shadowsocks-libev
#


FROM golang:1.13.5-alpine AS builder
RUN set -ex \
	&& apk add --no-cache git \
	&& mkdir -p /go/src/github.com/shadowsocks \
	&& cd /go/src/github.com/shadowsocks \
	&& git clone https://github.com/shadowsocks/v2ray-plugin.git \
	&& cd v2ray-plugin \
	&& go get -d \
	&& go build -o /go/bin/v2ray-plugin

FROM alpine:latest
LABEL maintainer="kev <noreply@datageek.info>, Sah <contact@leesah.name>"

ENV SERVER_ADDR 0.0.0.0
ENV SERVER_PORT 8388
ENV PASSWORD=
ENV METHOD      aes-256-gcm
ENV TIMEOUT     300
ENV DNS_ADDRS    8.8.8.8,8.8.4.4
ENV VER 3.3.3
ENV ARGS=

RUN mkdir /tmp/repo \ 
 && cd /tmp/repo \
 && wget --no-check-certificate https://github.com/shadowsocks/shadowsocks-libev/releases/download/v$VER/shadowsocks-libev-$VER.tar.gz \
 &&  tar xvf /tmp/repo/shadowsocks-libev-$VER.tar.gz \
 && set -ex \
 # Build environment setup \
 && apk add --no-cache --virtual .build-deps \
      autoconf \
      automake \
      build-base \
      c-ares-dev \
      libcap \
      libev-dev \
      libtool \
      libsodium-dev \
      linux-headers \
      mbedtls-dev \
      pcre-dev \
 # Build & install
 && cd /tmp/repo/shadowsocks-libev-$VER \
 && autoreconf --install --force \
 && ./configure --prefix=/usr --disable-documentation \
 && make install \
 && ls /usr/bin/ss-* | xargs -n1 setcap cap_net_bind_service+ep \
 && apk del .build-deps \
 # Runtime dependencies setup
 && apk add --no-cache \
      ca-certificates \
      tzdata \
      rng-tools \
      $(scanelf --needed --nobanner /usr/bin/ss-* \
      | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
      | xargs -r apk info --installed \
      | sort -u) \
 && rm -rf /tmp/repo

COPY --from=builder /go/bin/v2ray-plugin /usr/bin
COPY config_sample.json /etc/shadowsocks-libev/config.json
VOLUME /etc/shadowsocks-libev

ENV TZ=Asia/Shanghai

USER nobody


CMD [ "ss-server", "-c", "/etc/shadowsocks-libev/config.json" ]


#CMD exec ss-server \
#      -s $SERVER_ADDR \
#      -p $SERVER_PORT \
#      -k ${PASSWORD:-$(hostname)} \
#      -m $METHOD \
#      -t $TIMEOUT \
#      -d $DNS_ADDRS \
#      -u \
#      $ARGS
