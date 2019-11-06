#
# Dockerfile for shadowsocks-libev
#

FROM alpine
LABEL maintainer="kev <noreply@datageek.info>, Sah <contact@leesah.name>"

ENV SERVER_ADDR 0.0.0.0
ENV SERVER_PORT 8388
ENV PASSWORD=
ENV METHOD      aes-256-gcm
ENV TIMEOUT     300
ENV DNS_ADDRS    8.8.8.8,8.8.4.4
# ENV VER 3.3.3
ENV ARGS=
ARG ver
ARG shadowsocks_libev_ver
ARG download_link
RUN ver=$(wget --no-check-certificate -qO- https://api.github.com/repos/shadowsocks/shadowsocks-libev/releases/latest | grep 'tag_name' | cut -d\" -f4) \
    && [ -z ${ver} ] && echo "Error: Get shadowsocks-libev latest version failed" && exit 1 \
    && shadowsocks_libev_ver="shadowsocks-libev-$(echo ${ver} | sed -e 's/^[a-zA-Z]//g')" \
    && download_link="https://github.com/shadowsocks/shadowsocks-libev/releases/download/${ver}/${shadowsocks_libev_ver}.tar.gz" 


RUN mkdir /tmp/repo \ 
 && cd /tmp/repo \
# && wget --no-check-certificate https://github.com/shadowsocks/shadowsocks-libev/releases/download/v$VER/shadowsocks-libev-$VER.tar.gz \
  && wget --no-check-certificate $download_link \
# &&  tar xvf /tmp/repo/shadowsocks-libev-$VER.tar.gz \
 && tar xvf /tmp/repo/$shardowsocks_libev_ver.tar.gz
 && set -ex \
 # Build environment setup \
 && apk add --no-cache --virtual .build-deps \
      autoconf \
      automake \
      build-base \
      c-ares-dev \
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
 && apk del .build-deps \
 # Runtime dependencies setup
 && apk add --no-cache \
      ca-certificates \
      rng-tools \
      $(scanelf --needed --nobanner /usr/bin/ss-* \
      | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
      | sort -u) \
 && rm -rf /tmp/repo

USER nobody

CMD exec ss-server \
      -s $SERVER_ADDR \
      -p $SERVER_PORT \
      -k ${PASSWORD:-$(hostname)} \
      -m $METHOD \
      -t $TIMEOUT \
      -d $DNS_ADDRS \
      -u \
      $ARGS
