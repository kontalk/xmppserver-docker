#!/usr/bin/env bash
set -e

function urlencode() {
    echo -n "$1" | perl -pe 's/([^a-zA-Z0-9_.!~*()'\''-])/sprintf("%%%02X", ord($1))/ge'
}

# create SSL certificate if needed
SSL_CERT="${HOME}/kontalk-server/certs/${XMPP_SERVICE}.pem"
mkdir -p $(dirname ${SSL_CERT})
if [ ! -f /tmp/data/privatekey.pem ] || [ ! -f /tmp/data/certificate.pem ];
then
    if [ "${CERT_LETSENCRYPT}" == "true" ]; then
        echo "Let's Encrypt certificates are not supported yet."
        exit 1
    else
        echo "Generating SSL certificate"
        openssl req -x509 -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=${XMPP_SERVICE}" -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes
        cat cert.pem key.pem >${SSL_CERT} &&
        rm cert.pem key.pem
    fi
else
    echo "Using provided SSL certificate"
    cat /tmp/data/certificate.pem /tmp/data/privatekey.pem >${SSL_CERT}
    [ -f /tmp/data/cachain.pem ] && cat /tmp/data/cachain.pem >>${SSL_CERT}
fi

# create GPG key if needed
if [ ! -f /tmp/data/server-private.key ] || [ ! -f /tmp/data/server-public.key ];
then
    echo "Generating GPG key pair"
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
    export FINGERPRINT=$(gpg2 --with-colons --with-fingerprint --list-secret-keys ${KEY_USERID} | grep fpr | head -n 1 | awk '{print $10}' FS=:)
    if [ "${FINGERPRINT}" == "" ]; then
        echo "GPG key not found!"
        exit 1
    fi
else
    echo "Using provided GPG key pair"
    export FINGERPRINT=$(gpg2 --with-colons --import --import-options=import-show /tmp/data/server-private.key /tmp/data/server-public.key | grep fpr | head -n 1 | awk '{print $10}' FS=:)
    if [ "${FINGERPRINT}" == "" ]; then
        echo "Could not import existing GPG key!"
        exit 1
    fi
fi

# create database if needed
if [ ! -f ${HOME}/.databasesetup ];
then
    echo "Waiting for database"
    wait-for-it db:3306 -q -t 0
    echo "Creating database"

    # create tigase database objects
    cd ${HOME}/kontalk-server/tigase-server
    rm -f jars/*.jar
    cp ../jars/*.jar jars/
    java -cp "jars/*" tigase.util.DBSchemaLoader -dbHostname db -dbType mysql -schemaVersion 7-1 \
        -dbName ${MYSQL_DATABASE} -dbUser ${MYSQL_USER} -dbPass ${MYSQL_PASSWORD} \
        -rootUser root -rootPass ${MYSQL_ROOT_PASSWORD} \
        -adminJID admin@${XMPP_SERVICE} -adminJIDpass dummy \
        -logLevel ALL -useSSL false -serverTimezone ${MYSQL_TIMEZONE}
    cd - >/dev/null

    # create kontalk database objects
    cd ${HOME}/kontalk-server/tigase-extension
    mvn flyway:baseline \
        -Dflyway.url=jdbc:mysql://db/${MYSQL_DATABASE}?serverTimezone=$(urlencode ${MYSQL_TIMEZONE}) \
        -Dflyway.user=${MYSQL_USER} -Dflyway.password=${MYSQL_PASSWORD} -Dflyway.baselineVersion=${DATABASE_BASELINE}
    mvn flyway:migrate \
        -Dflyway.url=jdbc:mysql://db/${MYSQL_DATABASE}?serverTimezone=$(urlencode ${MYSQL_TIMEZONE}) \
        -Dflyway.user=${MYSQL_USER} -Dflyway.password=${MYSQL_PASSWORD}
    cd - >/dev/null

    # replace our server entry
    mysql -h db --port 3306 -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} <<EOF
REPLACE INTO servers (fingerprint, host, enabled) VALUES('${FINGERPRINT}', '${XMPP_SERVICE}', 1);
EOF

    touch ${HOME}/.databasesetup
fi

# copy some other stuff
cp /tmp/data/tigase.conf ${HOME}/kontalk-server/etc/tigase.conf
cp /tmp/data/trusted.pem ${HOME}/kontalk-server/trusted.pem
[[ -f /tmp/data/truststore ]] && cp /tmp/data/truststore ${HOME}/kontalk-server/truststore

# export keys to file
gpg2 --export ${FINGERPRINT} >${HOME}/kontalk-server/server-public.key
gpg2 --export-secret-key ${FINGERPRINT} >${HOME}/kontalk-server/server-private.key

cd ${HOME}/kontalk-server
exec dockerize \
 -template /tmp/data/init.properties.in:etc/init.properties \
 -wait tcp://db:3306 \
 scripts/tigase.sh run etc/tigase.conf
