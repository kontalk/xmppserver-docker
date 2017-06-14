#!/usr/bin/env bash
# pre-hook script for certbot
# shuts down the containers

echo "Stopping Kontalk server."
$(dirname $0)/../launcher stop
