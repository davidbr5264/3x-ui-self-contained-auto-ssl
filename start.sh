#!/bin/sh
set -ex # Exit immediately if a command fails and print commands.

# --- Configuration ---
ACME_SH_PATH="/opt/acme.sh/acme.sh"
XUI_DIR="/usr/local/x-ui"
DB_PATH="/etc/x-ui/x-ui.db"
CERT_PATH="/etc/x-ui/server.crt"
KEY_PATH="/etc/x-ui/server.key"
CONFIG_JSON_PATH="${XUI_DIR}/config/config.json"
WEB_PORT=2053

# --- Pre-flight Checks ---
# 1. Always remove the default config file to ensure database settings are used.
if [ -f "${CONFIG_JSON_PATH}" ]; then
    echo "Removing default config.json to enforce database settings."
    rm -f "${CONFIG_JSON_PATH}"
fi

# 2. Ensure database file exists. If not, create it.
if [ ! -f "${DB_PATH}" ]; then
    echo "Database not found. Initializing it now."
    cd "${XUI_DIR}"
    ./x-ui migrate
fi

# --- Unconditional HTTPS Configuration ---
# 3. Forcefully apply the entire HTTPS configuration on EVERY container start.
echo "Enforcing HTTPS configuration now..."
sqlite3 "${DB_PATH}" "UPDATE settings SET \
    web_listen = '0.0.0.0', \
    web_port = ${WEB_PORT}, \
    web_enable_https = true, \
    web_cert_path = '${CERT_PATH}', \
    web_key_path = '${KEY_PATH}' \
    WHERE id = 1;"
echo "HTTPS configuration has been enforced."

# --- Certificate Generation ---
# 4. Generate certificate only if the file is missing.
if [ ! -f "${CERT_PATH}" ]; then
    echo "Certificate file not found. Generating new SSL certificate for ${DOMAIN}..."
    DOMAIN=${DOMAIN:-"your.domain.com"}
    EMAIL=${EMAIL:-"your-email@example.com"}

    ${ACME_SH_PATH} --issue -d "${DOMAIN}" --standalone --httpport ${WEB_PORT} -m "${EMAIL}" --force --server letsencrypt
    ${ACME_SH_PATH} --install-cert -d "${DOMAIN}" \
        --cert-file      "${CERT_PATH}" \
        --key-file       "${KEY_PATH}" \
        --fullchain-file /etc/x-ui/server.pem
    echo "SSL certificate generation complete."
fi

# --- Start Application ---
echo "Starting 3x-ui panel..."
cd "${XUI_DIR}"
exec ./x-ui
