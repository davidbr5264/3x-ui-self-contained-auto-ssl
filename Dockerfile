# Use a lightweight base image
FROM alpine:latest

# Install necessary packages
RUN apk update && apk add --no-cache \
    curl \
    socat \
    tar

# Install acme.sh for SSL certificate management
RUN curl https://get.acme.sh | sh

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
