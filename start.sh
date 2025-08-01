#!/bin/sh

# Define the path to the acme.sh script
ACME_SH_PATH="/opt/acme.sh/acme.sh"

# --- RUNTIME VERIFICATION ---
# Immediately exit if acme.sh is not found
if [ ! -f "${ACME_SH_PATH}" ]; then
  echo "FATAL ERROR: acme.sh script not found at ${ACME_SH_PATH}"
  exit 1
fi

# Set default values for environment variables if they are not provided
DOMAIN=${DOMAIN:-"your.domain.com"}
EMAIL=${EMAIL:-"your-email@example.com"}

# Check if a certificate already exists
if [ ! -f /etc/x-ui/server.crt ]; then
  echo "Certificate not found. Issuing a new one for ${DOMAIN}..."
  
  # Issue a new certificate using acme.sh from its absolute path
  # Use --server letsencrypt for explicit CA and --force for scripting
  ${ACME_SH_PATH} --issue \
    -d "${DOMAIN}" \
    --standalone \
    -m "${EMAIL}" \
    --force \
    --server letsencrypt
  
  echo "Installing certificate to /etc/x-ui/..."
  # Install the certificate to the appropriate location for 3x-ui
  ${ACME_SH_PATH} --install-cert \
    -d "${DOMAIN}" \
    --cert-file      /etc/x-ui/server.crt \
    --key-file       /etc/x-ui/server.key \
    --fullchain-file /etc/x-ui/server.pem
fi

echo "Starting 3x-ui panel..."
# Start the 3x-ui panel
/usr/local/x-ui/x-ui
