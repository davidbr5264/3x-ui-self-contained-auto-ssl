#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.

# Define paths
ACME_SH_PATH="/opt/acme.sh/acme.sh"
XUI_DIR="/usr/local/x-ui"
XUI_BIN_PATH="${XUI_DIR}/x-ui"
DB_PATH="/etc/x-ui/x-ui.db"
CERT_PATH="/etc/x-ui/server.crt"
KEY_PATH="/etc/x-ui/server.key"

# --- First-Run Database Initialization and HTTPS Configuration ---
# If the database file does not exist, this is the first run.
if [ ! -f "${DB_PATH}" ]; then
    echo "--- FIRST RUN DETECTED ---"
    echo "Initializing database..."
    
    # Change to the application's directory to run migration
    cd "${XUI_DIR}"
    
    # Use the 'migrate' command to create and populate the database with defaults
    ./x-ui migrate
    
    echo "Database initialized. Forcing HTTPS configuration using correct column names..."
    
    # --- THIS IS THE CRITICAL FIX ---
    # Update the settings table to ENABLE HTTPS and set certificate paths using snake_case.
    sqlite3 "${DB_PATH}" "UPDATE settings SET web_enable_https = true, web_cert_path = '${CERT_PATH}', web_key_path = '${KEY_PATH}' WHERE id = 1;"
    
    echo "HTTPS configuration applied. Verifying settings:"
    
    # Verify by reading the values back from the database using the correct column names
    sqlite3 "${DB_PATH}" "SELECT 'web_enable_https:', web_enable_https, 'web_cert_path:', web_cert_path, 'web_key_path:', web_key_path FROM settings WHERE id = 1;"
    
    echo "---------------------------"
fi


# --- Certificate Generation (acme.sh) ---
if [ ! -f "${CERT_PATH}" ]; then
  echo "Certificate not found. Issuing a new one for ${DOMAIN}..."
  
  DOMAIN=${DOMAIN:-"your.domain.com"}
  EMAIL=${EMAIL:-"your-email@example.com"}

  ${ACME_SH_PATH} --issue \
    -d "${DOMAIN}" \
    --standalone \
    -m "${EMAIL}" \
    --force \
    --server letsencrypt

  echo "Installing certificate to /etc/x-ui/..."
  ${ACME_SH_PATH} --install-cert \
    -d "${DOMAIN}" \
    --cert-file      "${CERT_PATH}" \
    --key-file       "${KEY_PATH}" \
    --fullchain-file /etc/x-ui/server.pem
fi

echo "Starting 3x-ui panel..."

# Change to the application's directory before running it
cd "${XUI_DIR}"

# Execute the binary from its own directory
exec ./x-ui
