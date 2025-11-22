#!/bin/bash
set -e

echo "==================================="
echo "Beethovens Werkstatt API Startup"
echo "==================================="

# Remove old API versions that may have been restored
echo "Cleaning up old API packages..."
rm -f /opt/exist/autodeploy/api-0.1.0.xar /opt/exist/autodeploy/api-0.2.0.xar

echo "==================================="
echo "Beethovens Werkstatt API Ready"
echo "API will be available after eXist-DB starts"
echo "API Documentation: http://localhost:8080/docs"
echo "OpenAPI Spec: http://localhost:8080/openapi.json"
echo "==================================="

# Execute the base image entrypoint with its default command
# This will start eXist-DB in the foreground
exec /__cacert_entrypoint.sh ./entrypoint.sh
