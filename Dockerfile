FROM alpine:latest

# Install dependencies: curl (for acme.sh), socat (for acme.sh standalone), jq (for config manipulation)
RUN apk add --no-cache curl socat jq

# Install acme.sh (for auto SSL)
RUN curl https://get.acme.sh | sh

# Clone 3x-ui (replace with binary installation if available for even lighter image)
RUN mkdir -p /opt && \
    cd /opt && \
    curl -L $(curl -s https://api.github.com/repos/MHSanaei/3x-ui/releases/latest \
      | jq -r '.assets[] | select(.name | test("linux_amd64")) | .browser_download_url') \
      -o 3x-ui && chmod +x 3x-ui

WORKDIR /opt

# Create folder for SSL certs
RUN mkdir -p /opt/ssl

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80 443

ENTRYPOINT ["/entrypoint.sh"]
