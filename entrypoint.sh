#!/bin/bash

# Set defaults if not provided
DOMAIN="${DOMAIN:-yourdomain.com}"
ADMIN_USER="${ADMIN_USER:-admin}"
ADMIN_PASS="${ADMIN_PASS:-$(tr -dc A-Za-z0-9 </dev/urandom | head -c 16)}"

# Generate Caddyfile
cat > /etc/caddy/Caddyfile <<EOF
${DOMAIN} {
    reverse_proxy localhost:2053
    tls {
        dns cloudflare {env.CF_API_TOKEN}
        issuer acme {
            email ${SSL_EMAIL:-admin@${DOMAIN}}
        }
    }
}
EOF

# Initialize 3x-ui if first run
if [ ! -f /etc/x-ui/x-ui.db ]; then
    /usr/local/x-ui/x-ui <<CONFIG
1
2053
${ADMIN_USER}
${ADMIN_PASS}
/etc/x-ui/ssl/cert.pem
/etc/x-ui/ssl/key.pem
CONFIG

    # Link Caddy certs to 3x-ui
    ln -s /data/caddy/certificates/*/${DOMAIN}/${DOMAIN}.crt /etc/x-ui/ssl/cert.pem
    ln -s /data/caddy/certificates/*/${DOMAIN}/${DOMAIN}.key /etc/x-ui/ssl/key.pem
fi

# Start services
/usr/local/x-ui/x-ui &
caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
