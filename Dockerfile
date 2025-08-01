# Use a lightweight base image
FROM alpine:latest

# Install necessary packages
RUN apk update && apk add --no-cache \
    curl \
    socat \
    tar \
    coreutils \
    git \
    openssl

# --- acme.sh INSTALLATION ---
RUN git clone https://github.com/acmesh-official/acme.sh.git /opt/acme.sh && \
    chmod +x /opt/acme.sh/acme.sh

# --- VERIFY acme.sh ---
RUN if [ ! -x /opt/acme.sh/acme.sh ]; then echo "acme.sh not found or not executable"; exit 1; fi

# --- CORRECTED 3x-ui INSTALLATION & VERIFICATION ---
# Download, extract, and then immediately verify the executable exists and is executable
RUN wget -O /usr/local/3x-ui.tar.gz "https://github.com/MHSanaei/3x-ui/releases/latest/download/x-ui-linux-amd64.tar.gz" && \
    tar -zxvf /usr/local/3x-ui.tar.gz -C /usr/local/ && \
    rm /usr/local/3x-ui.tar.gz && \
    chmod +x /usr/local/x-ui/x-ui && \
    if [ ! -x /usr/local/x-ui/x-ui ]; then \
        echo "Error: /usr/local/x-ui/x-ui not found or not executable after extraction."; \
        ls -la /usr/local/; \
        exit 1; \
    fi

# Create necessary directories
RUN mkdir -p /etc/x-ui/ && \
    mkdir -p /var/log/x-ui/

# Copy the startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Set the entrypoint to the startup script
ENTRYPOINT ["/bin/sh", "/start.sh"]
