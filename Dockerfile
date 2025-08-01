# --- Stage 1: Build Environment ---
FROM alpine:latest AS builder

# Set build arguments for architecture
ARG TARGETARCH=amd64
ARG XUI_DOWNLOAD_URL="https://github.com/MHSanaei/3x-ui/releases/latest/download/x-ui-linux-${TARGETARCH}.tar.gz"

# Install build-time dependencies
RUN apk update && apk add --no-cache curl tar git

# Download and prepare acme.sh
RUN git clone https://github.com/acmesh-official/acme.sh.git /opt/acme.sh && \
    chmod +x /opt/acme.sh/acme.sh

# Download and prepare the correct 3x-ui binary
RUN echo "Downloading 3x-ui for architecture: ${TARGETARCH} from ${XUI_DOWNLOAD_URL}" && \
    wget -O /tmp/3x-ui.tar.gz "${XUI_DOWNLOAD_URL}" && \
    tar -zxvf /tmp/3x-ui.tar.gz -C /usr/local/ && \
    chmod +x /usr/local/x-ui/x-ui

# --- Stage 2: Final Image ---
FROM alpine:latest

# Install runtime-only dependencies
RUN apk update && apk add --no-cache \
    socat \
    coreutils \
    openssl \
    ca-certificates

# Create necessary directories
RUN mkdir -p /etc/x-ui/ /var/log/x-ui/ /opt/

# Copy the pre-built components from the builder stage
COPY --from=builder /opt/acme.sh /opt/acme.sh
COPY --from=builder /usr/local/x-ui /usr/local/x-ui

# --- VERIFICATION STEP ---
RUN if [ ! -x /usr/local/x-ui/x-ui ]; then echo "FATAL: x-ui binary not copied correctly"; exit 1; fi
RUN if [ ! -x /opt/acme.sh/acme.sh ]; then echo "FATAL: acme.sh not copied correctly"; exit 1; fi

# Copy the startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Set the entrypoint
ENTRYPOINT ["/bin/sh", "/start.sh"]
