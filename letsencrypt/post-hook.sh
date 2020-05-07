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

    cp ${LIVEDIR}/cert.pem ../config/certificate.pem
    cp ${LIVEDIR}/privkey.pem ../config/privatekey.pem
    cp ${LIVEDIR}/chain.pem ../config/cachain.pem
}

if [ -z "${XMPP_SERVICE}" ]; then
    echo "No domain defined. Skipping certificate installation."
else
    install_certificate "${XMPP_SERVICE}"
fi

echo "Restarting Kontalk server."
../launcher restart
