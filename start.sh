#!/bin/sh

# Set default values for environment variables if they are not provided
DOMAIN=${DOMAIN:-"your.domain.com"}
EMAIL=${EMAIL:-"your-email@example.com"}

# Check if a certificate already exists
if [ ! -f /etc/x-ui/server.crt ]; then
  # If no certificate exists, issue a new one using acme.sh
  /root/.acme.sh/acme.sh --issue \
    -d "${DOMAIN}" \
    --standalone \
    -m "${EMAIL}" \
    --force

  # Install the certificate to the appropriate location for 3x-ui
  /root/.acme.sh/acme.sh --install-cert \
    -d "${DOMAIN}" \
    --cert-file      /etc/x-ui/server.crt \
    --key-file       /etc/x-ui/server.key \
    --fullchain-file /etc/x-ui/server.pem
fi

# Start the 3x-ui panel
/usr/local/x-ui/x-ui
