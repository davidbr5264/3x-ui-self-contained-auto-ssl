#!/bin/bash

# Set default values for username and password if not provided
XUI_USERNAME=${XUI_USERNAME:-admin}
XUI_PASSWORD=${XUI_PASSWORD:-admin}

# Configure the panel with environment variables
/usr/local/x-ui/x-ui setting -username ${XUI_USERNAME} -password ${XUI_PASSWORD} -port ${XUI_PORT}

# Check if a domain is provided for SSL
if [ -n "${XUI_DOMAIN}" ]; then
  echo "Domain provided: ${XUI_DOMAIN}. Attempting to obtain SSL certificate."

  # Stop any process that might be using port 80
  fuser -k 80/tcp

  # Install Acme.sh for SSL
  curl https://get.acme.sh | sh
  source ~/.acme.sh/acme.sh.env

  # Issue SSL certificate
  ~/.acme.sh/acme.sh --issue -d ${XUI_DOMAIN} --standalone

  # Install the certificate for x-ui
  ~/.acme.sh/acme.sh --install-cert -d ${XUI_DOMAIN} \
    --key-file /usr/local/x-ui/server.key \
    --fullchain-file /usr/local/x-ui/server.crt

  # Set up cron job for automatic renewal
  (crontab -l 2>/dev/null; echo "0 0 * * * ~/.acme.sh/acme.sh --cron -d ${XUI_DOMAIN} > /dev/null") | crontab -

fi

# Start cron service
service cron start

# Execute the CMD
exec "$@"
