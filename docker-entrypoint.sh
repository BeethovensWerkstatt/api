#!/bin/bash
set -e

echo "==================================="
echo "Beethovens Werkstatt API"
echo "==================================="
echo "Environment: ${BW_ENV:-production}"
echo "eXist-db Context: ${EXIST_CONTEXT_PATH:-/}"
echo ""

# Remove old API versions that may have been restored from backup
echo "Cleaning up old API packages..."
rm -f /opt/exist/autodeploy/api-0.1.0.xar /opt/exist/autodeploy/api-0.2.0.xar 2>/dev/null || true

# List current packages
echo "Current packages in autodeploy:"
ls -la /opt/exist/autodeploy/*.xar 2>/dev/null || echo "  (none)"

echo ""
echo "==================================="
echo "Starting eXist-db..."
echo ""
echo "Endpoints (after startup):"
echo "  - API:       http://localhost:8080/"
echo "  - API Docs:  http://localhost:8080/api/docs"
echo "  - Health:    http://localhost:8080/api/health"
echo "  - OpenAPI:   http://localhost:8080/api/openapi.json"
echo "==================================="
echo ""

# Execute the base image entrypoint
exec /__cacert_entrypoint.sh ./entrypoint.sh
