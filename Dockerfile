# Stage 1: Build the website
FROM alpine:3.18 AS builder

# Install Zola 0.22.1 from official release (apk ships 0.17.2 which lacks Giallo highlighting)
RUN apk add --no-cache curl tar && \
    curl -sSL https://github.com/getzola/zola/releases/download/v0.22.1/zola-v0.22.1-x86_64-unknown-linux-musl.tar.gz \
    | tar -xz -C /usr/local/bin

# Set the working directory
WORKDIR /site

# Copy the website files
COPY . .

# Check Zola configuration
RUN zola check

# Debug: Show the content of config.toml
RUN cat config.toml

# Build the website with verbose output
RUN zola build

# Stage 2: Serve the website
FROM caddy:2-alpine

# Copy the built website from the builder stage
COPY --from=builder /site/public /usr/share/caddy

# Copy Caddyfile
COPY Caddyfile /etc/caddy/Caddyfile

# Expose port 80 and 443
EXPOSE 80
EXPOSE 443

# Start Caddy
CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile"]
