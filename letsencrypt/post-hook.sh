#!/usr/bin/env bash
# post-hook script for certbot
# installs certificates and starts the containers
set -e

cd "$(dirname "$0")"

. ../local.properties

install_certificate() {
    DOMAIN="$1"
    LIVEDIR="/etc/letsencrypt/live/${DOMAIN}"
    if [ ! -d ${LIVEDIR} ]; then
        >&2 echo "Error: certificates not found."
        return
    fi

    # download CA certificates
    wget https://letsencrypt.org/certs/letsencryptauthorityx3.pem -O /tmp/level2.pem
    wget https://letsencrypt.org/certs/isrgrootx1.pem -O /tmp/level1.pem

    cp ${LIVEDIR}/cert.pem ../config/certificate.pem
    cp ${LIVEDIR}/privkey.pem ../config/privatekey.pem
    cat /tmp/level2.pem /tmp/level1.pem >../config/cachain.pem
}

if [ -z "${XMPP_SERVICE}" ]; then
    echo "No domain defined. Skipping certificate installation."
else
    install_certificate "${XMPP_SERVICE}"
fi

echo "Starting Kontalk server."
../launcher start
