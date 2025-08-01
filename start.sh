#!/bin/sh

# Define paths
ACME_SH_PATH="/opt/acme.sh/acme.sh"
XUI_DIR="/usr/local/x-ui"
XUI_BIN_PATH="${XUI_DIR}/x-ui"

# --- RUNTIME VERIFICATION ---
if [ ! -f "${ACME_SH_PATH}" ]; then
  echo "FATAL ERROR: acme.sh script not found at ${ACME_SH_PATH}"
  exit 1
fi

if [ ! -f "${XUI_BIN_PATH}" ]; then
  echo "FATAL ERROR: 3x-ui binary not found at ${XUI_BIN_PATH}"
  exit 1
fi

# Set default values for environment variables
DOMAIN=${DOMAIN:-"your.domain.com"}
EMAIL=${EMAIL:-"your-email@example.com"}

# Check if a certificate already exists
if [ ! -f /etc/x-ui/server.crt ]; then
  echo "Certificate not found. Issuing a new one for ${DOMAIN}..."

  ${ACME_SH_PATH} --issue \
    -d "${DOMAIN}" \
    --standalone \
    -m "${EMAIL}" \
    --force \
    --server letsencrypt

  echo "Installing certificate to /etc/x-ui/..."
  ${ACME_SH_PATH} --install-cert \
    -d "${DOMAIN}" \
    --cert-file      /etc/x-ui/server.crt \
    --key-file       /etc/x-ui/server.key \
    --fullchain-file /etc/x-ui/server.pem
fi

echo "Starting 3x-ui panel..."

# --- FIX: Change to the application's directory before running it ---
cd "${XUI_DIR}" || exit

# Execute the binary from its own directory
exec ./x-ui
