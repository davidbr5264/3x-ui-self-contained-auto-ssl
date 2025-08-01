#!/bin/sh

CERT_PATH="/opt/ssl/cert.pem"
KEY_PATH="/opt/ssl/key.pem"
CONFIG_PATH="/opt/config.json"
DOMAIN=${DOMAIN}
EMAIL=${EMAIL}

# Issue cert if not present
if [ ! -f "$CERT_PATH" ] && [ -n "$DOMAIN" ] && [ -n "$EMAIL" ]; then
  ~/.acme.sh/acme.sh --issue --standalone -d "$DOMAIN" --email "$EMAIL" --keylength ec-256
  ~/.acme.sh/acme.sh --install-cert -d "$DOMAIN" \
    --ecc \
    --cert-file $CERT_PATH \
    --key-file $KEY_PATH \
    --fullchain-file /opt/ssl/fullchain.pem
fi

# Update the config file with new cert/key paths if config exists
if [ -f "$CONFIG_PATH" ]; then
  jq --arg cert "$CERT_PATH" --arg key "$KEY_PATH" \
    '.ssl.cert = $cert | .ssl.key = $key' "$CONFIG_PATH" > "${CONFIG_PATH}.tmp" && mv "${CONFIG_PATH}.tmp" "$CONFIG_PATH"
fi

# Start 3x-ui (update with actual config arguments if needed)
./3x-ui
