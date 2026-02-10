FROM nginx:1.27-alpine
# CACHE_BUST: fix-502-errors-v10-force-clean-rebuild# CACHE_BUST: docker-entrypoint.d cleanup v6

# Remove default entrypoint scripts that interfere with our custom configuration
RUN rm -rf /docker-entrypoint.d/

# Copy custom entrypoint script
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Copy nginx config template
COPY nginx.conf.template /etc/nginx/nginx.conf.template

# Install dependencies for template substitution
RUN apk add --no-cache gettext apache2-utils && \
    mkdir -p /etc/nginx/conf.d

    EXPOSE 80

    # Use custom entrypoint to substitute variables and start nginx
    ENTRYPOINT ["/docker-entrypoint.sh"]
