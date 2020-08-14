FROM golang:1.14.7-alpine3.12 AS builder

LABEL maintainer="Emmanuel Postigo <ascende.superius@protonmail.com>"

#ARG CADDY_TAG="v2.0.0-beta.20"
#ARG CADDYSRC_PATH="cmd/xcaddy/main.go"

RUN apk --no-cache add git \
		       build-base \
		       gcc

WORKDIR /go/src/app

# Download caddy builder tool
#RUN git clone https://github.com/caddyserver/builder.git .
#RUN go build "$CADDYSRC_PATH build" "$CADDY_TAG" --with "$CADDY_PLUGIN"
RUN go get -u github.com/caddyserver/xcaddy/cmd/xcaddy
RUN xcaddy build

FROM alpine:3.12.0

ARG GOSU_VERSION="1.11"
ARG CADDY_HOME="/var/lib/caddy"

# install caddy
COPY --from=builder /go/src/app/caddy /usr/bin/caddy

# validate install
RUN /usr/bin/caddy version
RUN /usr/bin/caddy environ

# install gosu ( instructions from https://cinhtau.net/2017/06/19/install-gosu-for-docker/ )
#RUN apk add --no-cache --virtual .gosu-deps \
#        dpkg \
#        gnupg \
#        openssl \
#	wget \
#    && dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
#    && wget -O /usr/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" \
#    && wget -O /usr/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc" \
#    && export GNUPGHOME="$(mktemp -d)" \
#    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
#    && gpg --batch --verify /usr/bin/gosu.asc /usr/bin/gosu \
#    && rm -r "$GNUPGHOME" /usr/bin/gosu.asc \
#    && chmod +x /usr/bin/gosu \
#    && gosu nobody true \
#    && apk del .gosu-deps

# From gosu, https://github.com/tianon/gosu/blob/master/INSTALL.md
ENV GOSU_VERSION 1.12
RUN set -eux; \
  \
  apk add --no-cache --virtual .gosu-deps \
    ca-certificates \
    dpkg \
    gnupg \
    ; \
  \
  dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
  wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
  wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
  \
  # verify the signature
  export GNUPGHOME="$(mktemp -d)"; \
  gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
  gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
  command -v gpgconf && gpgconf --kill all || :; \
  rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
  \
  # clean up fetch dependencies
  apk del --no-network .gosu-deps; \
  \
  chmod +x /usr/local/bin/gosu; \
  # verify that the binary works
  gosu --version; \
  gosu nobody true

RUN apk --no-cache add libcap

EXPOSE 80 443 2015

WORKDIR /var/lib/caddy

ENV UID="1000"
ENV GID="1000"

COPY docker-entrypoint.sh /usr/bin
RUN chmod +x /usr/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["caddy","version"]
