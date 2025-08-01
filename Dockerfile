# Use a lightweight base image
FROM alpine:latest

# Install necessary packages, including git and openssl for acme.sh
RUN apk update && apk add --no-cache \
    curl \
    socat \
    tar \
    coreutils \
    git \
    openssl

# Install acme.sh to a predictable, absolute path and verify it
RUN git clone https://github.com/acmesh-official/acme.sh.git /opt/acme.sh && \
    cd /opt/acme.sh && \
    ./acme.sh --install --home /opt/acme.sh --accountemail "my@example.com" && \
    apk del git

# --- VERIFICATION STEP ---
# This command will fail the build if acme.sh is not found or not executable
RUN if [ ! -f /opt/acme.sh/acme.sh ] || [ ! -x /opt/acme.sh/acme.sh ]; then \
    echo "Error: /opt/acme.sh/acme.sh not found or not executable."; \
    ls -la /opt/acme.sh/; \
    exit 1; \
    fi

# Set the latest version of 3x-ui
ARG XUI_VERSION=latest

# Download and install 3x-ui
RUN wget -O /usr/local/3x-ui.tar.gz "https://github.com/MHSanaei/3x-ui/releases/latest/download/x-ui-linux-amd64.tar.gz" && \
    tar -zxvf /usr/local/3x-ui.tar.gz -C /usr/local/ && \
    rm /usr/local/3x-ui.tar.gz && \
    chmod +x /usr/local/x-ui/x-ui

# Create necessary directories
RUN mkdir -p /etc/x-ui/ && \
    mkdir -p /var/log/x-ui/

# Copy the startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Set the entrypoint to the startup script
ENTRYPOINT ["/bin/sh", "/start.sh"]
