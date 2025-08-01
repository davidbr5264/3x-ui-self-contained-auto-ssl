# --- Stage 1: Build Environment ---
# We can still use alpine here as it's just for downloading
FROM alpine:latest AS builder

# Install build-time dependencies
RUN apk update && apk add --no-cache curl tar git

# Download and prepare acme.sh
RUN git clone https://github.com/acmesh-official/acme.sh.git /opt/acme.sh && \
    chmod +x /opt/acme.sh/acme.sh

# Download and prepare 3x-ui for amd64
RUN wget -O /tmp/3x-ui.tar.gz "https://github.com/MHSanaei/3x-ui/releases/latest/download/x-ui-linux-amd64.tar.gz" && \
    tar -zxvf /tmp/3x-ui.tar.gz -C /usr/local/ && \
    chmod +x /usr/local/x-ui/x-ui

# --- Stage 2: Final Production Image (Using Debian) ---
# Use debian:slim as the base, which includes glibc
FROM debian:slim

# Set a non-interactive frontend to prevent prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install runtime-only dependencies for Debian
RUN apt-get update && apt-get install -y --no-install-recommends \
    socat \
    coreutils \
    openssl \
    ca-certificates \
    curl \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create necessary directories
RUN mkdir -p /etc/x-ui/ /var/log/x-ui/ /opt/

# Copy the pre-built components from the builder stage
COPY --from=builder /opt/acme.sh /opt/acme.sh
COPY --from=builder /usr/local/x-ui /usr/local/x-ui

# Copy the startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Set the entrypoint
ENTRYPOINT ["/bin/sh", "/start.sh"]
