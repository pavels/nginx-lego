#!/bin/sh

hash_certs() {
    find /var/lego/certificates \
        -type f \
        -exec python -sBc "import hashlib;print hashlib.md5(open('{}','rb').read()).hexdigest()" \;
}
PRE_HASH=$(hash_certs)

lego \
    --path="/var/lego" \
    --server="${LEGO_SERVER:=https://acme-v01.api.letsencrypt.org/directory}" \
    --email="${EMAIL}" \
    --domains=${DOMAIN} \
    --dns="${DNS_PROVIDER}" \
    renew \
    --days="${RENEW_DAYS:="30"}"

if [ "${PRE_HASH}" = "$(hash_certs)" ]; then
    echo "Certificate is still valid for at least ${RENEW_DAYS} days."
    exit 0
fi

supervisorctl -c /supervisord.conf restart nginx
