# Railway Nginx Password Auth

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/iC1z8D?referralCode=Dk06R-&utm_medium=integration&utm_source=template&utm_campaign=generic)

A lightweight nginx-based reverse proxy with HTTP Basic Authentication, designed for deployment on Railway and other container platforms.

## 🚀 Quick Deploy

**Option 1: One-Click Railway Template**
Click the "Deploy on Railway" button above for instant deployment with auto-configured settings.

**Option 2: Manual Setup**
Follow the instructions below for custom configuration.

## Features

- 🔒 **Secure by Default** - Requires Basic Authentication unless explicitly disabled
- 🚀 **WebSocket Support** - Full support for WebSocket connections
- 🐳 **Docker Ready** - Built on Alpine Linux for minimal footprint
- ⚡ **Railway Optimized** - Designed specifically for Railway deployments
- 🔧 **Environment Configurable** - Easy setup via environment variables
- 🐛 **Debug Friendly** - Clear error messages for faster troubleshooting

## Environment Variables

| Variable           | Required | Description                                         | Example                     |
| ------------------ | -------- | --------------------------------------------------- | --------------------------- |
| `ORIGIN`           | ✅       | The upstream URL to proxy to                        | `https://myapp.railway.app` |
| `BASIC_AUTH`       | ✅\*     | Username and password in `username:password` format | `admin:mysecretpass`        |
| `BASIC_AUTH_REALM` | ❌       | Authentication realm message                        | `"Restricted Area"`         |
| `ALLOW_NO_AUTH`    | ❌       | Set to `"true"` to disable auth requirement         | `"true"`                    |

\*Required by default for security. Set `ALLOW_NO_AUTH=true` to make it optional.

## Use Cases

### Protecting Development/Staging Environments

```bash
# Protect your staging app with basic auth (using Railway private networking)
ORIGIN=http://myapp.railway.internal:3000
BASIC_AUTH=dev:staging123
BASIC_AUTH_REALM="Staging Environment"
```

### Adding Auth to Public APIs

```bash
# Add authentication layer to an existing API
ORIGIN=https://api.myservice.com
BASIC_AUTH=client:api-key-here
```

## Troubleshooting

### Common Issues

**"ORIGIN env var is required" error:**

- Make sure you've set the `ORIGIN` environment variable
- Verify the URL format includes protocol (http:// or https://)

**"BASIC_AUTH is required for security" error:**

- Set `BASIC_AUTH=username:password` to enable authentication
- Or set `ALLOW_NO_AUTH=true` to disable the auth requirement

**"BASIC_AUTH must be in 'username:password' format" error:**

- Ensure your `BASIC_AUTH` value contains exactly one colon
- Format: `username:password`

**"Failed to create htpasswd file" error:**

- Check that your password doesn't contain special characters that might cause issues
- Try a simpler password to test

**502 Bad Gateway:**

- Check that your `ORIGIN` URL is accessible
- Verify the upstream service is running
- Ensure network connectivity between proxy and origin

**"Invalid nginx configuration" error:**

- Check the container logs for specific nginx configuration errors
- Verify that all environment variables are set correctly

### Logs

View container logs to debug issues:

```bash
docker logs <container-id>
```

On Railway, check the deployment logs in your project dashboard.

## Quick Start

### Local Development

1. **Build the Docker image:**

   ```bash
   docker build -t nginx-revproxy .
   ```

2. **Run with Basic Auth (default behavior):**

   ```bash
   docker run -p 8080:80 \
     -e ORIGIN="http://host.docker.internal:3000" \
     -e BASIC_AUTH="admin:supersecret" \
     nginx-revproxy
   ```

3. **Run without authentication (requires explicit override):**
   ```bash
   docker run -p 8080:80 \
     -e ORIGIN="http://host.docker.internal:3000" \
     -e ALLOW_NO_AUTH="true" \
     nginx-revproxy
   ```

## License

MIT License - feel free to use this in your projects!
