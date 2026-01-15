# Development Guide

This guide explains how to set up and work with the Beethovens Werkstatt API locally.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Development Workflow](#development-workflow)
- [Testing](#testing)
- [Docker Development](#docker-development)
- [Configuration](#configuration)
- [RESTXQ API Development](#restxq-api-development)
- [Troubleshooting](#troubleshooting)

## Prerequisites

- **Node.js** 20+ (for build tools)
- **Docker** and **Docker Compose** (for containerized development)
- **Git** (for data repositories)
- **eXist-db** 6.x (optional, for non-Docker development)

## Quick Start

### Using Docker (Recommended)

```bash
# Clone the repository
git clone https://github.com/BeethovensWerkstatt/api.git
cd api

# Install dependencies
npm install

# Start development environment
npm run docker:dev

# The API will be available at:
# - Main: http://localhost:8080/exist/apps/api/
# - API: http://localhost:8080/exist/apps/api/api/
# - Swagger UI: http://localhost:8080/exist/apps/api/api/docs
```

### Without Docker

```bash
# Install dependencies
npm install

# Fetch data repositories
npm run fetch-data

# Build the application
npm run build

# Watch for changes during development
npm run watch

# Deploy to local eXist-db instance manually
```

## Project Structure

```
api/
├── build/               # Build output (git-ignored)
│   ├── data/            # Cloned data repository
│   ├── data-cache/      # Cloned data-cache repository
│   └── resources/       # Compiled XQuery modules
├── config/              # Environment configuration files
│   ├── development.xml  # Development settings
│   ├── staging.xml      # Staging settings
│   └── production.xml   # Production settings
├── docs/                # Documentation
├── scripts/             # Build and utility scripts
├── source/              # Source code
│   ├── eXist-db/        # eXist-db package files
│   ├── html/            # Static HTML files
│   ├── xql/             # XQuery endpoint scripts
│   ├── xqm/             # XQuery library modules
│   │   ├── rest/        # RESTXQ API modules
│   │   └── util/        # Utility modules
│   └── xslt/            # XSLT stylesheets
├── test/                # Test files
│   └── xqsuite/         # XQSuite test modules
├── .github/workflows/   # CI/CD configuration
├── docker-compose.yml   # Production Docker setup
└── docker-compose.dev.yml # Development Docker setup
```

## Development Workflow

### Building

```bash
# Full build (includes data fetch)
npm run build

# Build without fetching data
npm run dist

# Watch mode (rebuilds on file changes)
npm run watch
```

### Data Management

```bash
# Fetch data repositories (auto-detects branch)
npm run fetch-data

# Force specific data branch
npm run fetch-data -- --branch dev

# Check for data updates (dry run)
node scripts/fetch-data.js --check

# Clean and re-fetch data
node scripts/fetch-data.js --clean
```

### Creating a Package

```bash
# Create XAR package
npm run package

# The package will be in dist/api-{version}.xar
```

## Testing

### Running Tests

```bash
# Run all XQSuite tests
npm run test

# Run tests against specific eXist-db instance
EXIST_HOST=localhost EXIST_PORT=8080 npm run test
```

### Writing Tests

Tests are located in `test/xqsuite/` and use the XQSuite framework:

```xquery
xquery version "3.1";

module namespace my-tests = "http://beethovens-werkstatt.de/ns/test/my-tests";

import module namespace test = "http://exist-db.org/xquery/xqsuite" at "resource:org/exist/xquery/lib/xqsuite/xqsuite.xql";

declare
    %test:name("should do something")
    %test:assertEquals("expected result")
function my-tests:test-something() {
    "expected result"
};
```

### Test Categories

- **config-tests.xqm** - Configuration and environment tests
- **validation-tests.xqm** - Input validation tests
- **iiif-tests.xqm** - IIIF API endpoint tests

## Docker Development

### Development Mode

```bash
# Start with hot-reload
npm run docker:dev

# Stop
npm run docker:dev:stop

# View logs
docker-compose -f docker-compose.dev.yml logs -f

# Rebuild after dependency changes
docker-compose -f docker-compose.dev.yml build
```

### Production Mode

```bash
# Start production container
EXIST_PASSWORD=your-secure-password docker-compose up -d

# Stop
docker-compose down

# View logs
docker-compose logs -f api
```

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `EXIST_PASSWORD` | Admin password (required in production) | - |
| `BW_ENV` | Environment name | `development` |
| `EXIST_CONTEXT_PATH` | eXist-db context path | `/exist` |
| `JAVA_OPTS` | JVM options | `-Xms512m -Xmx2g` |

## Configuration

Environment-specific settings are in `config/`:

```xml
<!-- config/development.xml -->
<config>
    <environment>development</environment>
    
    <features>
        <debug-mode>true</debug-mode>
        <enable-swagger>true</enable-swagger>
        <enable-caching>false</enable-caching>
    </features>
    
    <logging>
        <level>DEBUG</level>
        <include-stack-traces>true</include-stack-traces>
    </logging>
</config>
```

Access configuration in XQuery:

```xquery
import module namespace config = "http://beethovens-werkstatt.de/ns/config" at "../config.xqm";

(: Get current environment :)
config:get-env()

(: Check if feature is enabled :)
config:is-enabled('debug-mode')

(: Get config value :)
config:get('logging/level')
```

## RESTXQ API Development

### Creating Endpoints

RESTXQ modules are in `source/xqm/rest/`:

```xquery
xquery version "3.1";

module namespace my-api = "http://beethovens-werkstatt.de/ns/api/my-api";

import module namespace http = "http://beethovens-werkstatt.de/ns/http" at "../util/http.xqm";

(:~
 : List all items
 : @return JSON array of items
 :)
declare
    %rest:GET
    %rest:path("/api/items")
    %rest:produces("application/json")
    %output:method("json")
function my-api:list-items() {
    http:cors-headers(),
    array {
        for $item in collection('/db/apps/api/data')//item
        return map {
            "id": $item/@xml:id/string(),
            "label": $item/label/string()
        }
    }
};

(:~
 : Get single item
 : @param $id Item identifier
 : @return JSON object
 :)
declare
    %rest:GET
    %rest:path("/api/items/{$id}")
    %rest:produces("application/json")
    %output:method("json")
function my-api:get-item($id as xs:string) {
    let $item := collection('/db/apps/api/data')//item[@xml:id = $id]
    return
        if ($item) then (
            http:cors-headers(),
            map {
                "id": $item/@xml:id/string(),
                "label": $item/label/string(),
                "data": serialize($item, map { "method": "json" })
            }
        ) else
            http:not-found("Item not found: " || $id)
};
```

### URL Structure

- **RESTXQ endpoints**: `/api/*` (forwarded to RestXqServlet)
- **Legacy endpoints**: `/iiif/*`, `/module1/*`, etc. (handled by controller.xql)

### Adding New API Modules

1. Create module in `source/xqm/rest/`
2. Register in `source/eXist-db/post-install.xql`
3. Add tests in `test/xqsuite/`
4. Document in OpenAPI spec

## Troubleshooting

### Common Issues

**Container won't start**
```bash
# Check logs
docker-compose logs -f

# Check if port is in use
lsof -i :8080

# Reset and rebuild
docker-compose down -v
docker-compose build --no-cache
docker-compose up
```

**Data not loading**
```bash
# Check data versions
cat build/data-versions.json

# Re-fetch data
npm run fetch-data -- --clean
```

**Tests failing**
```bash
# Ensure eXist-db is running
curl http://localhost:8080/exist/

# Check test logs
cat test-results/*.xml
```

**RESTXQ endpoints not working**
1. Check module is registered in post-install.xql
2. Verify RESTXQ annotations are correct
3. Check controller.xql forwards the path
4. Check eXist-db logs for errors

### Useful Commands

```bash
# Check eXist-db status
curl http://localhost:8080/exist/apps/api/api/health

# View OpenAPI spec
curl http://localhost:8080/exist/apps/api/api/openapi.json | jq

# List deployed apps
curl -u admin:password http://localhost:8080/exist/rest/db/apps/

# View eXist-db logs in container
docker exec -it bw-api tail -f /exist/logs/exist.log
```

## Contributing

1. Create a feature branch from `dev`
2. Make changes following the coding standards
3. Add tests for new functionality
4. Update documentation as needed
5. Submit a pull request

### Code Style

- Use consistent indentation (2 spaces for XQuery)
- Add JSDoc-style comments to functions
- Follow XQuery 3.1 best practices
- Keep modules focused and small

### Commit Messages

Follow conventional commits:
```
feat: add new IIIF endpoint for annotations
fix: correct manifest generation for multi-page documents
docs: update API documentation
test: add tests for validation module
chore: update dependencies
```
