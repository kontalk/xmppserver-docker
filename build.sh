#!/usr/bin/env bash
set -e

DATADIR=data
SSL_TRUSTED=trusted.pem
TIGASE_CONF=init.properties.in
HTTUPLOAD_CONF=config.yml.in

. tigase.properties

function create_gpgkey()
{
    export GNUPGHOME=$(mktemp -d)
    KEY_USERID="kontalk-${RANDOM}@${XMPP_SERVICE}"
    gpg2 --batch --gen-key <<EOF
%no-protection
Key-Type: 1
Key-Length: 2048
Subkey-Type: 1
Subkey-Length: 2048
Name-Real: Kontalk server
Name-Email: ${KEY_USERID}
Expire-Date: 0
EOF

    # get GPG key fingerprint
    FINGERPRINT=$(gpg2 --with-colons --with-fingerprint --list-secret-keys ${KEY_USERID} | grep fpr | head -n 1 | awk '{print $10}' FS=:)
    if [ "${FINGERPRINT}" == "" ]; then
        echo "GPG key not found!"
        return 1
    fi

    # export the newly created keys
    gpg2 --export ${FINGERPRINT} >${DATADIR}/server-public.key
    gpg2 --export-secret-key ${FINGERPRINT} >${DATADIR}/server-private.key

    echo ${FINGERPRINT}
    return 0
}

MODE=$1

if [ "${MODE}" != "dev" ] && [ "${MODE}" != "prod" ]; then
    echo "Usage: $0 [dev|prod]"
    exit 1
fi

# check XMPP service name
if [ "${XMPP_SERVICE}" == "" ]; then
    echo "You must define a XMPP_SERVICE in the tigase.properties file."
    exit 1
fi

# check GPG key
if [ ! -f ${DATADIR}/server-private.key ] || [ ! -f ${DATADIR}/server-public.key ]; then
    if [ "$MODE" == "dev" ]; then
        echo "Not using provided GPG server key, I'll generate one automatically."
    else
        echo "Generating new GPG server key."
        if ! FINGERPRINT=$(create_gpgkey); then
            echo "We could not create a new GPG key for your server."
            echo "Please create or provide one and export it into ${DATADIR}/server-private.key and ${DATADIR}/server-public.key"
            exit 1
        fi
        export FINGERPRINT
    fi
fi

# check GPG key
if [ ! -f ${DATADIR}/privatekey.pem ] || [ ! -f ${DATADIR}/certificate.pem ]; then
    if [ "$MODE" == "dev" ]; then
        echo "Not using provided X.509 certificate, I'll generate one automatically."
    else
        echo "You must provide an existing X.509 certificate for the server."
        echo "Please copy it into ${DATADIR}/privatekey.pem and ${DATADIR}/certificate.pem"
        echo "An optional CA chain can be provided into ${DATADIR}/cachain.pem"
        exit 1
    fi
fi

# check trusted.pem
if [ ! -f ${DATADIR}/${SSL_TRUSTED} ];
then
    # copy default trusted certs bundle
    echo "Using default trusted certs bundle"
    cp ${DATADIR}/${SSL_TRUSTED}.dist ${DATADIR}/${SSL_TRUSTED}
fi

# check init.properties
if [ ! -f ${DATADIR}/${TIGASE_CONF} ];
then
    echo "Using default Tigase configuration"
    cp ${DATADIR}/${TIGASE_CONF}.dist ${DATADIR}/${TIGASE_CONF}
fi

# check config.yml (httpupload)
if [ ! -f ${DATADIR}/${HTTUPLOAD_CONF} ];
then
    echo "Using default HTTP upload component configuration"
    cp ${DATADIR}/${HTTUPLOAD_CONF}.dist ${DATADIR}/${HTTUPLOAD_CONF}
fi

echo "Building images"
$(dirname $0)/tigase/build.sh >/dev/null
$(dirname $0)/httpupload/build.sh >/dev/null

echo "Resetting containers"
docker-compose rm -f
docker-compose build
