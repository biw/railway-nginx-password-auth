#!/bin/bash
set -e

if [ -z "$ORIGIN" ]; then
    echo "ERROR: ORIGIN env var is required"
        exit 1
        fi

        if [ -z "$OPENCLAW_GATEWAY_TOKEN" ]; then
            echo "ERROR: OPENCLAW_GATEWAY_TOKEN env var is required"
                exit 1
                fi

                echo "🚀 Starting nginx with ORIGIN: $ORIGIN and TOKEN: ${OPENCLAW_GATEWAY_TOKEN:0:10}..."

                if [ -f "/etc/nginx/nginx.conf.template" ]; then
                    echo "📝 Generating nginx.conf from template..."
                        ORIGIN="$ORIGIN" \
                            TOKEN="$OPENCLAW_GATEWAY_TOKEN" \
                                envsubst '${ORIGIN} ${TOKEN}' \
                                    < /etc/nginx/nginx.conf.template \
                                        > /etc/nginx/nginx.conf
                                        fi

                                        if [ ! -z "$BASIC_AUTH" ]; then
                                            echo "🔐 Creating HTTP Basic Auth..."
                                                echo "$BASIC_AUTH" | htpasswd -i -c /etc/nginx/.htpasswd -
                                                fi

                                                echo "✓ Validating nginx configuration..."
                                                if ! nginx -t 2>&1; then
                                                    echo "❌ nginx configuration test failed!"
                                                        exit 1
                                                        fi

                                                        echo "✓ Configuration valid"
                                                        echo "🌐 Starting nginx..."
                                                        exec nginx -g "daemon off;"
