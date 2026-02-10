#!/bin/bash
set -e

# =============================================================================
# Docker Entrypoint Script for nginx OpenClaw Authentication Proxy
# 
# Purpose: Substitute environment variables into the nginx configuration
#          template and start the nginx service
#
# Requirements:
#   - OPENCLAW_GATEWAY_TOKEN: Bearer token for OpenClaw authentication
#   - ORIGIN: OpenClaw backend service URL
#   - Optional: BASIC_AUTH_USERNAME, BASIC_AUTH_PASSWORD for HTTP auth
# =============================================================================

echo "════════════════════════════════════════════════════════════════════"
echo "🚀 Docker Entrypoint: Nginx OpenClaw Authentication Proxy"
echo "════════════════════════════════════════════════════════════════════"

# ─────────────────────────────────────────────────────────────────────────
# Step 1: Verify Required Environment Variables
# ─────────────────────────────────────────────────────────────────────────

echo ""
echo "📋 Step 1: Validating environment variables..."

if [ -z "$ORIGIN" ]; then
    echo "❌ ERROR: ORIGIN env var is required (e.g., http://openclaw-main.railway.internal:8080)"
        exit 1
        fi
        echo "✓ ORIGIN is set"

        if [ -z "$OPENCLAW_GATEWAY_TOKEN" ]; then
            echo "❌ ERROR: OPENCLAW_GATEWAY_TOKEN env var is required"
                exit 1
                fi
                echo "✓ OPENCLAW_GATEWAY_TOKEN is set"

                # ─────────────────────────────────────────────────────────────────────────
                # Step 2: Export Variables for envsubst
                # 
                # IMPORTANT: envsubst needs variables in the environment to substitute them
                # ─────────────────────────────────────────────────────────────────────────

                echo ""
                echo "📋 Step 2: Exporting variables for template substitution..."

                export ORIGIN="$ORIGIN"
                export TOKEN="$OPENCLAW_GATEWAY_TOKEN"

                echo "✓ ORIGIN exported: ${ORIGIN}"
                echo "✓ TOKEN exported (first 10 chars): ${TOKEN:0:10}..."

                # ─────────────────────────────────────────────────────────────────────────
                # Step 3: Ensure Configuration Directory Exists
                # ─────────────────────────────────────────────────────────────────────────

                echo ""
                echo "📋 Step 3: Preparing nginx configuration directory..."

                mkdir -p /etc/nginx/conf.d
                echo "✓ /etc/nginx/conf.d directory exists"

                # ─────────────────────────────────────────────────────────────────────────
                # Step 4: Generate nginx Configuration from Template
                # 
                # The template uses ${ORIGIN} and ${TOKEN} placeholders which envsubst will
                # replace with actual values from the environment
                # ─────────────────────────────────────────────────────────────────────────

                echo ""
                echo "📋 Step 4: Generating nginx configuration from template..."

                if [ ! -f "/etc/nginx/nginx.conf.template" ]; then
                    echo "❌ ERROR: Template file not found at /etc/nginx/nginx.conf.template"
                        exit 1
                        fi
                        echo "✓ Template file found: /etc/nginx/nginx.conf.template"

                        # Run envsubst to replace ${ORIGIN} and ${TOKEN} with actual values
                        envsubst '$ORIGIN $TOKEN' < /etc/nginx/nginx.conf.template > /etc/nginx/conf.d/default.conf

                        echo "✓ Configuration generated: /etc/nginx/conf.d/default.conf"

                        # ─────────────────────────────────────────────────────────────────────────
                        # Step 5: Verify Template Substitution Was Successful
                        # 
                        # Check that the placeholders were actually replaced in the output file
                        # ─────────────────────────────────────────────────────────────────────────

                        echo ""
                        echo "📋 Step 5: Verifying template substitution..."

                        if grep -q '${TOKEN}' /etc/nginx/conf.d/default.conf; then
                            echo "❌ ERROR: Template placeholder \${TOKEN} was NOT substituted!"
                                echo "   This means the Bearer token was not injected into the configuration."
                                    echo "   Check that OPENCLAW_GATEWAY_TOKEN environment variable is set."
                                        exit 1
                                        fi
                                        echo "✓ TOKEN placeholder was substituted successfully"

                                        if grep -q '${ORIGIN}' /etc/nginx/conf.d/default.conf; then
                                            echo "❌ ERROR: Template placeholder \${ORIGIN} was NOT substituted!"
                                                echo "   This means the backend origin was not injected into the configuration."
                                                    echo "   Check that ORIGIN environment variable is set."
                                                        exit 1
                                                        fi
                                                        echo "✓ ORIGIN placeholder was substituted successfully"

                                                        # Verify Bearer token appears in the config
                                                        if grep -q "Authorization: Bearer" /etc/nginx/conf.d/default.conf; then
                                                            echo "✓ Bearer token authentication header is present in configuration"
                                                            else
                                                                echo "⚠ WARNING: Bearer token authentication header not found in configuration"
                                                                fi

                                                                # ─────────────────────────────────────────────────────────────────────────
                                                                # Step 6: Validate nginx Configuration
                                                                # ─────────────────────────────────────────────────────────────────────────

                                                                echo ""
                                                                echo "📋 Step 6: Validating nginx configuration syntax..."

                                                                if ! nginx -t 2>&1; then
                                                                    echo "❌ ERROR: nginx configuration validation failed!"
                                                                        exit 1
                                                                        fi
                                                                        echo "✓ nginx configuration is valid"

                                                                        # ─────────────────────────────────────────────────────────────────────────
                                                                        # Step 7: Create HTTP Basic Authentication (if configured)
                                                                        # 
                                                                        # If BASIC_AUTH environment variable is set in Railway, use it
                                                                        # This adds an additional layer of security
                                                                        # ─────────────────────────────────────────────────────────────────────────

                                                                        echo ""
                                                                        echo "📋 Step 7: Checking HTTP Basic Authentication..."

                                                                        if [ ! -z "$BASIC_AUTH" ]; then
                                                                            echo "✓ HTTP Basic Authentication is enabled"
                                                                                echo "  Creating .htpasswd file..."

                                                                                        echo "$BASIC_AUTH" | htpasswd -i -c /etc/nginx/.htpasswd - > /dev/null 2>&1

                                                                                                echo "✓ .htpasswd file created successfully"
                                                                                                else
                                                                                                    echo "ℹ HTTP Basic Authentication is not configured (optional)"
                                                                                                    fi
                                                                                                    
                                                                                                    # ─────────────────────────────────────────────────────────────────────────
                                                                                                    # Step 8: Start nginx
                                                                                                    # ─────────────────────────────────────────────────────────────────────────
                                                                                                    
                                                                                                    echo ""
                                                                                                    echo "════════════════════════════════════════════════════════════════════"
                                                                                                    echo "✅ All checks passed! Starting nginx..."
                                                                                                    echo "════════════════════════════════════════════════════════════════════"
                                                                                                    echo ""
                                                                                                    echo "Configuration Details:"
                                                                                                    echo "  - Backend Origin: $ORIGIN"
                                                                                                    echo "  - Bearer Token (first 10 chars): ${TOKEN:0:10}..."
                                                                                                    echo "  - Config File: /etc/nginx/conf.d/default.conf"
                                                                                                    echo ""
                                                                                                    echo "════════════════════════════════════════════════════════════════════"
                                                                                                    echo ""
                                                                                                    
                                                                                                    # Start nginx in foreground mode (required for Docker containers)
                                                                                                    exec nginx -g "daemon off;"
