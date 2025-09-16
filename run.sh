# Railway Nginx Password Auth - Local Testing Script

echo "Building nginx reverse proxy..."
docker build -t nginx-revproxy .

echo ""
echo "Test 1: With authentication (default behavior)"
echo "URL: http://localhost:8080"
echo "Credentials: admin / supersecret"
docker run -d --name nginx-test-auth -p 8080:80 \
  -e ORIGIN="https://httpbin.org" \
  -e BASIC_AUTH="admin:supersecret" \
  -e BASIC_AUTH_REALM="Test Environment" \
  nginx-revproxy

echo ""
echo "Test 2: Without authentication (override)"
echo "URL: http://localhost:8081"
docker run -d --name nginx-test-no-auth -p 8081:80 \
  -e ORIGIN="https://httpbin.org" \
  -e ALLOW_NO_AUTH="true" \
  nginx-revproxy

echo ""
echo "Tests running:"
echo "- Auth required: http://localhost:8080 (admin:supersecret)"
echo "- No auth: http://localhost:8081"
echo ""
echo "To stop tests: docker stop nginx-test-auth nginx-test-no-auth && docker rm nginx-test-auth nginx-test-no-auth"
