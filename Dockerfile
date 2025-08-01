# Use a lightweight base image
FROM debian:bullseye-slim

# Set environment variables
ENV XUI_VERSION=latest
ENV XUI_DOMAIN=""
ENV XUI_USERNAME=""
ENV XUI_PASSWORD=""
ENV XUI_PORT=2053
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && \
    apt-get install -y curl wget socat cron jq && \
    rm -rf /var/lib/apt/lists/*

# Install 3x-ui
RUN bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)

# Create a script to run on container start
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose the panel port
EXPOSE 2053

# Set the entrypoint
ENTRYPOINT ["/entrypoint.sh"]

# Set the default command
CMD ["/usr/local/x-ui/x-ui"]
