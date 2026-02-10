FROM nginx:1.27-alpine

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

COPY nginx.conf.template /etc/nginx/nginx.conf.template

RUN apk add --no-cache gettext apache2-utils

EXPOSE 80

ENTRYPOINT ["/docker-entrypoint.sh"]
