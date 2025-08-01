#!/bin/sh

# Define paths
ACME_SH_PATH="/opt/acme.sh/acme.sh"
XUI_DIR="/usr/local/x-ui"
XUI_BIN_PATH="${XUI_DIR}/x-ui"
DB_PATH="/etc/x-ui/x-ui.db"
CERT_PATH="/etc/x-ui/server.crt"
KEY_PATH="/etc/x-ui/server.key"

# --- First-Run Database Initialization ---
# If the database file does not exist, this is the first run.
if [ ! -f "${DB_PATH}" ]; then
    echo "First run detected. Initializing database and setting SSL paths..."
    
    # Change to the application's directory to run migration
    cd "${XUI_DIR}" || exit
    
    # Use the 'migrate' command to create and populate the database
    ./x-ui migrate
    
    # Now, update the settings table with the certificate paths
    sqlite3 "${DB_PATH}" "UPDATE settings SET webCertPath = '${CERT_PATH}', webKeyPath = '${KEY_PATH}' WHERE id = 1;"
    
    echo "Database initialized and SSL paths configured."
fi


# --- Certificate Generation (acme.sh) ---
# If the certificate file does not exist, issue one.
if [ ! -f "${CERT_PATH}" ]; then
  echo "Certificate not found. Issuing a new one for ${DOMAIN}..."
  
  # Set default values for environment variables if they are not provided
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
cd "${XUI_DIR}" || exit

# Execute the binary from its own directory
exec ./x-ui
