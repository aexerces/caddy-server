FROM golang:1.17-rc-alpine3.14 AS builder

LABEL maintainer="Emmanuel Postigo <ascende.superius@protonmail.com>"


RUN apk --no-cache add git \
		       build-base \
		       gcc

WORKDIR /go/src/app

RUN go get -u github.com/caddyserver/xcaddy/cmd/xcaddy
RUN xcaddy build --with github.com/caddy-dns/cloudflare@latest

FROM alpine:3.14.0

# install caddy
COPY --from=builder /go/src/app/caddy /usr/bin/caddy

# validate install
RUN /usr/bin/caddy version
RUN /usr/bin/caddy environ
RUN caddy list-modules

# From gosu, https://github.com/tianon/gosu/blob/master/INSTALL.md
ENV GOSU_VERSION 1.13
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

RUN apk --no-cache add \
        libcap \
        tini

EXPOSE 80 443 2015

WORKDIR /var/lib/caddy

ENV UID="1000"
ENV GID="1000"

VOLUME /var/lib/caddy
VOLUME /var/www/dev
VOLUME /var/log/caddy

COPY docker-entrypoint.sh /usr/bin
RUN chmod +x /usr/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["caddy","version"]
