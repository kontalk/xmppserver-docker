#!/usr/bin/env bash
set -e

# create SSL certificate if needed
SSL_CERT="${HOME}/HttpUploadComponent/server.crt"
SSL_KEY="${HOME}/HttpUploadComponent/server.key"
if [ ! -f ${SSL_CERT} ] || [ ! -f ${SSL_KEY} ];
then
    echo "Generating SSL certificate"
    openssl req -x509 -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=${XMPP_SERVICE}" -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes
    cp cert.pem ${SSL_CERT} &&
    cp key.pem ${SSL_KEY} &&
    rm cert.pem key.pem
fi

cd ${HOME}/HttpUploadComponent
dockerize \
 -template /tmp/config.yml.in:config.yml \
 -stdout httpupload.log \
 python3 httpupload/server.py --logfile httpupload.log
