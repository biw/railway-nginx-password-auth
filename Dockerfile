FROM nginx:1.27-alpine

# We need: envsubst (from gettext) and htpasswd (apache2-utils) to hash credentials
RUN apk add --no-cache bash gettext apache2-utils

# Where we'll drop an optional auth snippet
RUN mkdir -p /etc/nginx/snippets

# Template -> real conf at runtime
COPY nginx.conf.template /etc/nginx/templates/reverse.conf.template

# Entrypoint script runs after the stock nginx entrypoint setup
COPY docker-entrypoint.sh /docker-entrypoint.d/99-reverse-proxy.sh
RUN chmod +x /docker-entrypoint.d/99-reverse-proxy.sh

# Nginx listens on 80
EXPOSE 80

# Default envs (can be overridden at run time)
ENV ORIGIN=""
ENV BASIC_AUTH=""
ENV BASIC_AUTH_REALM="Restricted"

# Let the stock entrypoint handle templating + daemon
CMD ["nginx", "-g", "daemon off;"]
