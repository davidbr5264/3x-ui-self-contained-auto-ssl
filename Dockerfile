FROM caddy:builder AS caddy-builder
RUN xcaddy build \
    --with github.com/caddy-dns/cloudflare \
    --with github.com/mholt/caddy-dynamicdns

FROM ghcr.io/mhsanaei/3x-ui:latest

# Install dependencies and copy Caddy
RUN apk add --no-cache bash curl sqlite \
    && mkdir -p /etc/x-ui/ssl /data/caddy
COPY --from=caddy-builder /usr/bin/caddy /usr/bin/caddy

# Copy configuration scripts
COPY entrypoint.sh /usr/local/bin/
COPY healthcheck.sh /usr/local/bin/

# Configure services
EXPOSE 2053 80 443
VOLUME ["/etc/x-ui", "/data/caddy"]
HEALTHCHECK --interval=30s --timeout=3s CMD healthcheck.sh
ENTRYPOINT ["entrypoint.sh"]
