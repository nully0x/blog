# Stage 1: Build the website
FROM alpine:3.18 AS builder

# Install Zola (specify the version that matches your local installation)
RUN apk add --no-cache zola

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
