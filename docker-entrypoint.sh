#!/bin/ash

set +x

# Acces port 80 and 443 as non-root user
setcap 'cap_net_bind_service=+ep' /usr/bin/caddy

# get host user and group
UID=`cat /tmp/uag.id | head -1 | tail -1` 
GID=`cat /tmp/uag.id | head -2 | tail -1`

# create caddy group and user with UID and GID
adduser  -g $GID \
	 -u $UID \
	 -D \
	 -h /var/lib/caddy \
	 -H \
	 -s /sbin/nologin \
	 caddy

rm /tmp/uag.id

chown -R $UID:$GID /var/lib/caddy
exec gosu caddy "$@"

