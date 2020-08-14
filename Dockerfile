FROM golang:alpine AS builder

LABEL maintainer="Emmanuel Postigo <ascende.superius@protonmail.com>"

ARG CADDY_TAG="v2.0.0-beta.20"
ARG CADDYSRC_PATH="cmd/xcaddy/main.go"

RUN apk --no-cache add git \
		       build-base \
		       gcc

WORKDIR /go/src/app

# Download caddy builder tool
RUN git clone https://github.com/caddyserver/builder.git .
RUN go run "$CADDYSRC_PATH build" "$CADDY_TAG" --with "$CADDY_PLUGIN"

FROM alpine

ARG GOSU_VERSION="1.11"
ARG CADDY_HOME="/var/lib/caddy"

# install caddy
COPY --from=builder /go/src/app/caddy /usr/bin/caddy

# validate install
RUN /usr/bin/caddy version
RUN /usr/bin/caddy environ

# install gosu ( instructions from https://cinhtau.net/2017/06/19/install-gosu-for-docker/ )
RUN apk add --no-cache --virtual .gosu-deps \
        dpkg \
        gnupg \
        openssl \
	wget \
    && dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
    && wget -O /usr/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" \
    && wget -O /usr/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/bin/gosu.asc /usr/bin/gosu \
    && rm -r "$GNUPGHOME" /usr/bin/gosu.asc \
    && chmod +x /usr/bin/gosu \
    && gosu nobody true \
    && apk del .gosu-deps

RUN apk --no-cache add libcap

EXPOSE 80 443 2015

WORKDIR /var/lib/caddy

COPY docker-entrypoint.sh /usr/bin
RUN chmod +x /usr/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["caddy","version"]
