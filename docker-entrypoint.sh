#!/usr/bin/env bash
set -euo pipefail

# Fail fast if ORIGIN is missing
if [[ -z "${ORIGIN:-}" ]]; then
  echo "[entrypoint] ERROR: ORIGIN env var is required (e.g. app:3000 or example.com)"
  exit 1
fi

ORIGIN_WITH_HTTP="http://${ORIGIN}"



# Require BASIC_AUTH for easier debugging (set ALLOW_NO_AUTH=true to disable this check)
if [[ -z "${BASIC_AUTH:-}" && "${ALLOW_NO_AUTH:-}" != "true" ]]; then
  echo "[entrypoint] ERROR: BASIC_AUTH is required for security. Set BASIC_AUTH=username:password"
  echo "[entrypoint]        To disable auth requirement, set ALLOW_NO_AUTH=true"
  exit 1
fi

# Build Basic Auth snippet if BASIC_AUTH is provided
AUTH_SNIPPET="/etc/nginx/snippets/basic_auth.conf"
HTPASSWD_FILE="/etc/nginx/.htpasswd"

# Default: no auth
echo -n > "$AUTH_SNIPPET"

if [[ -n "${BASIC_AUTH:-}" ]]; then
  if [[ "$BASIC_AUTH" != *:* ]]; then
    echo "[entrypoint] ERROR: BASIC_AUTH must be in 'username:password' format"
    exit 1
  fi

  USERNAME="${BASIC_AUTH%%:*}"
  PASSWORD="${BASIC_AUTH#*:}"

  if [[ -z "$USERNAME" || -z "$PASSWORD" ]]; then
    echo "[entrypoint] ERROR: BASIC_AUTH username or password is empty"
    exit 1
  fi

  # Create bcrypt htpasswd. -b (batch), -B (bcrypt), -c (create)
  echo "[entrypoint] Creating htpasswd file for user '$USERNAME'..."
  if ! htpasswd -b -B -c "$HTPASSWD_FILE" "$USERNAME" "$PASSWORD"; then
    echo "[entrypoint] ERROR: Failed to create htpasswd file"
    exit 1
  fi

  # Verify the htpasswd file was created and has content
  if [[ ! -f "$HTPASSWD_FILE" || ! -s "$HTPASSWD_FILE" ]]; then
    echo "[entrypoint] ERROR: htpasswd file was not created or is empty"
    exit 1
  fi

  cat > "$AUTH_SNIPPET" <<EOF
auth_basic "${BASIC_AUTH_REALM:-Restricted}";
auth_basic_user_file $HTPASSWD_FILE;
EOF

  echo "[entrypoint] Basic Auth enabled for user '$USERNAME' with realm '${BASIC_AUTH_REALM:-Restricted}'"
else
  if [[ "${ALLOW_NO_AUTH:-}" == "true" ]]; then
    echo "[entrypoint] BASIC_AUTH not set — Basic Auth disabled (ALLOW_NO_AUTH=true)"
  fi
fi

# Detect DNS resolver to use - Railway uses IPv6 DNS for private networking
DNS_RESOLVER="127.0.0.11 8.8.8.8 8.8.4.4"

# Check if we're in Railway (or similar container platform with internal DNS)
if [[ -f /etc/resolv.conf ]]; then
  # Process nameservers and format IPv6 addresses correctly for nginx
  FORMATTED_NAMESERVERS=""
  while IFS= read -r nameserver; do
    if [[ -n "$nameserver" ]]; then
      # Check if it's an IPv6 address (contains colons)
      if [[ "$nameserver" == *":"* ]]; then
        # IPv6 addresses need brackets in nginx resolver directive
        FORMATTED_NAMESERVERS="$FORMATTED_NAMESERVERS [$nameserver]"
      else
        # IPv4 addresses don't need brackets
        FORMATTED_NAMESERVERS="$FORMATTED_NAMESERVERS $nameserver"
      fi
    fi
  done <<< "$(grep '^nameserver' /etc/resolv.conf | awk '{print $2}')"
  
  if [[ -n "$FORMATTED_NAMESERVERS" ]]; then
    # Use system nameservers first, then fallback to public DNS
    DNS_RESOLVER="$FORMATTED_NAMESERVERS 8.8.8.8 8.8.4.4"
    echo "[entrypoint] Using system DNS resolvers: $FORMATTED_NAMESERVERS"
  else
    echo "[entrypoint] No system nameservers found, using default resolvers"
  fi
fi

# Render nginx config from template with envsubst
if [[ ! -f /etc/nginx/templates/reverse.conf.template ]]; then
  echo "[entrypoint] ERROR: missing /etc/nginx/templates/reverse.conf.template"
  exit 1
fi

echo "[entrypoint] Generating nginx configuration with DNS resolver: $DNS_RESOLVER"
export DNS_RESOLVER
envsubst '\$ORIGIN_WITH_HTTP \$DNS_RESOLVER' < /etc/nginx/templates/reverse.conf.template > /etc/nginx/conf.d/reverse.conf

# Verify the config was generated
if [[ ! -f /etc/nginx/conf.d/reverse.conf || ! -s /etc/nginx/conf.d/reverse.conf ]]; then
  echo "[entrypoint] ERROR: Failed to generate nginx configuration"
  exit 1
fi

# Test nginx configuration syntax
echo "[entrypoint] Testing nginx configuration..."
if ! nginx -t; then
  echo "[entrypoint] ERROR: Invalid nginx configuration"
  exit 1
fi

# Remove the default nginx configuration to avoid conflicts
if [[ -f /etc/nginx/conf.d/default.conf ]]; then
  echo "[entrypoint] Removing default nginx configuration..."
  rm /etc/nginx/conf.d/default.conf
fi

echo "[entrypoint] Generated /etc/nginx/conf.d/reverse.conf with ORIGIN=$ORIGIN"
echo "[entrypoint] Configuration validated successfully"

# Hand back to the main process (the image's CMD)
