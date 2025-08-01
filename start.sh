#!/bin/sh

# Exit immediately if a command fails and print commands as they are executed.
set -ex

# --- Configuration ---
# Define paths and the web port
ACME_SH_PATH="/opt/acme.sh/acme.sh"
XUI_DIR="/usr/local/x-ui"
DB_PATH="/etc/x-ui/x-ui.db"
CERT_PATH="/etc/x-ui/server.crt"
KEY_PATH="/etc/x-ui/server.key"
CONFIG_JSON_PATH="${XUI_DIR}/config/config.json"
WEB_PORT=2053

# --- Pre-flight Check ---
# Always remove the default config file to ensure database settings are used.
if [ -f "${CONFIG_JSON_PATH}" ]; then
    echo "Removing default config.json to enforce database settings."
    rm -f "${CONFIG_JSON_PATH}"
fi

# --- First-Run: Database and Certificate Setup ---
# This block runs only if the database file does not already exist.
if [ ! -f "${DB_PATH}" ]; then
    echo "--- FIRST RUN DETECTED ---"

    # 1. Create database with default values
    echo "Initializing database..."
    cd "${XUI_DIR}"
    ./x-ui migrate

    # 2. Generate SSL certificate using the application's web port
    echo "Generating SSL certificate for ${DOMAIN} on port ${WEB_PORT}..."
    DOMAIN=${DOMAIN:-"your.domain.com"}
    EMAIL=${EMAIL:-"your-email@example.com"}

    ${ACME_SH_PATH} --issue -d "${DOMAIN}" --standalone --httpport ${WEB_PORT} -m "${EMAIL}" --force --server letsencrypt
    ${ACME_SH_PATH} --install-cert -d "${DOMAIN}" \
        --cert-file      "${CERT_PATH}" \
        --key-file       "${KEY_PATH}" \
        --fullchain-file /etc/x-ui/server.pem
    echo "SSL certificate generation complete."

    # 3. Apply a complete and forceful HTTPS configuration to the database
    echo "Applying forceful HTTPS configuration to database..."
    sqlite3 "${DB_PATH}" "UPDATE settings SET \
        web_listen = '0.0.0.0', \
        web_port = ${WEB_PORT}, \
        web_enable_https = true, \
        web_cert_path = '${CERT_PATH}', \
        web_key_path = '${KEY_PATH}' \
        WHERE id = 1;"

    echo "Configuration applied. Verifying settings from database:"
    sqlite3 "${DB_PATH}" "SELECT 'Listen IP:', web_listen, 'Port:', web_port, 'HTTPS Enabled:', web_enable_https, 'Cert Path:', web_cert_path FROM settings WHERE id = 1;"
    echo "--------------------------"
else
    echo "--- Database found, skipping first-run setup. ---"
fi

echo "Starting 3x-ui panel..."
cd "${XUI_DIR}"
exec ./x-ui
