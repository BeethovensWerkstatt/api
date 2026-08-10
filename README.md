# Beethovens Werkstatt API

This is the main data API of the Beethovens Werkstatt project. It provides access to MEI-encoded music data through various modules, with support for IIIF, genetic editions, and comparative analysis.

## Features

- **RESTXQ API** with custom `/api/` prefix routing
- **OpenAPI 3.0** specification with Swagger UI at `/api/docs`
- **IIIF Presentation API 2.1** support for document access
- **XQSuite Testing** framework for XQuery unit tests
- **Docker** support for development and production
- **Environment-based Configuration** (development, staging, production)
- **CI/CD Pipeline** with GitHub Actions

## Prerequisites

- Node.js 20 or later
- Git
- Docker (recommended) or local eXist-db 6.x instance

## Quick Start

### Docker (Recommended)

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
# - API endpoints: http://localhost:8080/exist/apps/api/api/
# - Swagger UI: http://localhost:8080/exist/apps/api/api/docs
# - Health check: http://localhost:8080/exist/apps/api/api/health
```

### Without Docker

```bash
# Install dependencies
npm install

# Configure eXist-db connection
cp .existdb.json.template .existdb.json
# Edit .existdb.json with your password

# Fetch data and build
npm run build:full

# Create distribution package
npm run package
```

## Documentation

- **[Development Guide](docs/DEVELOPMENT.md)** - Detailed development setup and workflow
- **[OpenAPI Specification](OPENAPI.md)** - API endpoint documentation
- **[API Docs (Swagger)](http://localhost:8080/exist/apps/api/api/docs)** - Interactive API explorer (when running with docker:dev)

## Available Commands

### Data Management

```bash
npm run fetch-data        # Clone/update data repositories
npm run fetch-data -- --branch dev  # Use specific data branch
npm run fetch-data -- --check       # Check for updates (dry run)
npm run fetch-data -- --clean       # Clean and re-fetch
```

**Branch mapping:**
- `data.git`: API `main` → data `main`, other branches → data `dev`
- `data-cache.git`: always uses `main` branch

### Building

```bash
npm run build             # Build for local (localhost:8080)
npm run build:public      # Build for production
npm run build:full        # Fetch data + build (local)
```

### Testing

```bash
npm run test              # Run XQSuite tests
```

### Packaging & Distribution

```bash
npm run package           # Create .xar file
npm run dist              # Build + package (production)
npm run dist:full         # Fetch data + build + package
```

### Development

```bash
npm run watch             # Watch files and auto-deploy to local eXist-db

# Docker-based development (recommended)
npm run docker:dev        # Start dev container with all eXist apps
npm run watch:docker      # Watch and deploy to Docker container
npm run docker:dev:logs   # View container logs
npm run docker:dev:stop   # Stop dev container
npm run docker:dev:rebuild # Rebuild package and restart container
```

### Deployment (xst)

```bash
npm run deploy            # Deploy entire build/
npm run deploy:xql        # Deploy XQuery scripts only
npm run deploy:xqm        # Deploy XQuery modules only
npm run deploy:xslt       # Deploy XSLT only
npm run deploy:controller # Deploy controller only
npm run install:xar       # Install .xar to eXist-db
```

## Project Structure

```
source/
├── eXist-db/        # eXist-DB configuration
├── xql/             # XQuery endpoints
├── xqm/             # XQuery modules
│   └── rest/        # RESTXQ API modules
├── xslt/            # XSLT transformations
└── html/            # HTML files

scripts/
├── utils.js         # Shared utilities
├── fetch-data.js    # Data repository management
├── build.js         # Main build script
├── package.js       # XAR creation
└── watch.js         # File watcher

build/               # Build output (not in git)
dist/                # Distribution packages (not in git)
```

## Adding New API Routes

All API routes are defined using RESTXQ in the `source/xqm/rest/` folder. The project uses a forwarding pattern where `controller.xql` forwards requests to the RestXqServlet.

### Step 1: Create or Update a RESTXQ Module

Create a new file in `source/xqm/rest/` (e.g., `my-api.xqm`):

```xquery
xquery version "3.1";

module namespace my-api = "https://api.beethovens-werkstatt.de/rest/my";

import module namespace api-base = "https://api.beethovens-werkstatt.de/rest/base" at "./api-base.xqm";

declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

(:~
 : List all items
 : @return JSON array of items
 :)
declare
    %rest:GET
    %rest:path("/my-module/items.json")
    %rest:produces("application/json")
    %output:method("json")
function my-api:list-items() {
    (: Option 1: Call existing XQL script :)
    api-base:forward-to-xql("/resources/xql/my-module/get-items.xql", map {})
    
    (: Option 2: Return data directly :)
    (: api-base:json-response(array { "item1", "item2" }) :)
};

(:~
 : Get specific item by ID
 : @param $id The item identifier
 : @return JSON item object
 :)
declare
    %rest:GET
    %rest:path("/my-module/{$id}.json")
    %rest:produces("application/json")
    %output:method("json")
function my-api:get-item($id as xs:string) {
    api-base:forward-to-xql("/resources/xql/my-module/get-item.xql", map {
        "item.id": $id
    })
};
```

### Step 2: Add Route Forwarding to controller.xql

Add a forwarding rule in `source/eXist-db/controller.xql` after the existing RESTXQ route sections:

```xquery
(: My Module Routes - my-api.xqm :)
if(starts-with(lower-case($exist:path), '/my-module/')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="/restxq{$exist:path}" absolute="yes"/>
    </dispatch>
) else
```

### Step 3: Deploy and Test

```bash
# If using file watcher, changes deploy automatically
npm run watch:docker

# Or manually deploy
npm run deploy
```

Test your endpoint:
```bash
curl http://localhost:8080/exist/apps/api/my-module/items.json
```

### Key Conventions

1. **Route paths** in RESTXQ should match the URL path without `/exist/apps/api` prefix
2. **CORS headers** are set automatically by `api-base:forward-to-xql()` or use `api-base:json-response()`
3. **Parameters** from URLs use `{$paramName}` syntax in `%rest:path`
4. **Query parameters** use `%rest:query-param("name", "{$var}", "default")`
5. **XQDoc comments** (`:~ ... :)`) become OpenAPI documentation

## eXist-DB Configuration

Create `.existdb.json` in the project root:

```json
{
  "servers": {
    "localhost": {
      "server": "http://localhost:8080/exist",
      "user": "admin",
      "password": "your-password"
    }
  }
}
```

## Data Repositories

This project requires data from two repositories:

- **data.git**: Main MEI data (uses `main` or `dev` branch)
- **data-cache.git**: Cached data (always uses `main`)

Data is fetched separately from the build process to enable caching and faster builds.

## Template Variables

During build, these variables are replaced:

- `$$deployTarget$$` → Base URI (local or production)
- `$$version$$` → package.json version
- `$$deployed$$` → ISO timestamp
- `$$desc$$` → package.json description
- `$$license$$` → package.json license
- `$$abbrev$$` → package.json name

## Development Workflow

### Docker-Based Development (Recommended)

The easiest way to develop is using the Docker development setup:

```bash
# 1. Set up passwords (first time only)
cp .env.template .env
cp .existdb.json.docker.template .existdb.json.docker
# Edit both files and set matching passwords

# 2. Build the package
npm run dist

# 3. Start development container
npm run docker:dev

# 4. In another terminal, watch for changes
npm run watch:docker

# Now edit files - they auto-deploy to the container
```

**Security Note:** The development setup uses a default password (`admin123`) if you don't configure `.env`. This is fine for local development since it's only accessible on `localhost`. For production, always use the production Dockerfile with a secure password.

**What you get:**
- API at `http://localhost:8080/exist/apps/api/`
- **eXide** at `http://localhost:8080/exist/apps/eXide/` (XQuery IDE)
- **Monex** at `http://localhost:8080/exist/apps/monex/` (Monitoring)
- Dashboard at `http://localhost:8080/exist/apps/dashboard/`
- REST API at `http://localhost:8080/exist/rest/`
- All RESTXQ endpoints
- Auto-deploy on file changes

**Advantages:**
- All eXist-DB apps available (eXide, Monex, etc.)
- No local eXist-DB installation needed
- Clean, reproducible environment
- Persisted data between restarts

### Traditional Development

If you prefer a local eXist-DB installation:

```bash
# Configure connection
cp .existdb.json.template .existdb.json
# Edit .existdb.json with your local eXist-DB details

# Watch and deploy
npm run watch
```

## Docker

The project includes a production-ready Dockerfile that builds a complete, self-contained container with eXist-DB 6.4.0 and all MEI data.

### Building the Image

```bash
# Build with data included (recommended for production)
docker build -t beethovens-werkstatt-api .

# This will:
# 1. Install Node.js dependencies
# 2. Fetch data from GitHub repositories (data.git + data-cache.git)
# 3. Build the package with production settings
# 4. Create a ~55MB .xar file with all data
# 5. Deploy to eXist-DB 6.4.0 container
```

**Build time:** ~30 seconds (including data fetch)

### Running the Container

```bash
# Start container on port 8080
# IMPORTANT: Set admin password via environment variable
docker run -d --name bw-api \
  -p 8080:8080 \
  -e EXIST_PASSWORD="your-secure-password" \
  beethovens-werkstatt-api

# Start on different port (e.g., 8082)
docker run -d --name bw-api \
  -p 8082:8080 \
  -e EXIST_PASSWORD="your-secure-password" \
  beethovens-werkstatt-api

# For development/testing only (uses base image default password)
docker run -d --name bw-api -p 8080:8080 beethovens-werkstatt-api
```

### Container Startup

The container takes **~60-90 seconds** to fully start:
1. eXist-DB starts (10-20s)
2. Package deploys and extracts data (30-50s)
3. RESTXQ modules register automatically (5-10s)

**Check if ready:**
```bash
# Should return documents (not 405 error)
curl http://localhost:8080/exist/restxq/iiif/documents.json
```

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `EXIST_ENV` | `development` | eXist-DB mode (`production` or `development`) |
| `EXIST_CONTEXT_PATH` | `/exist` | URL context path |
| `EXIST_PASSWORD` | *(base image default)* | Admin password (**MUST set for production!**) |

### Accessing the API

Once running, the API is available at:

- **API Base:** `http://localhost:8080/exist/apps/api/`
- **RESTXQ Endpoints:** `http://localhost:8080/exist/restxq/...`
- **OpenAPI Spec:** `http://localhost:8080/exist/apps/api/openapi.json`
- **Swagger UI:** `http://localhost:8080/exist/apps/api/docs`
- **eXist Dashboard:** `http://localhost:8080/exist/apps/dashboard/` (admin/admin123)

**Example requests:**
```bash
# List all IIIF documents
curl http://localhost:8080/exist/restxq/iiif/documents.json

# Get document data
curl http://localhost:8080/exist/restxq/data.json

# Get specific manifest
curl http://localhost:8080/exist/restxq/iiif/document/{documentId}/manifest.json
```

### Container Management

```bash
# View logs
docker logs bw-api

# Stop container
docker stop bw-api

# Start stopped container
docker start bw-api

# Remove container
docker rm -f bw-api

# Access container shell
docker exec -it bw-api bash
```

### Production Deployment

**Security requirements:**

1. **Always set admin password** via environment variable:
   ```bash
   docker run -e EXIST_PASSWORD="$(openssl rand -base64 32)" ...
   ```

2. **Use Docker secrets** for orchestration platforms:
   ```yaml
   # docker-compose.yml or kubernetes
   secrets:
     - exist_password
   environment:
     EXIST_PASSWORD_FILE: /run/secrets/exist_password
   ```

3. **Additional security measures:**
   - Use a reverse proxy (nginx, traefik) for SSL/TLS
   - Set up proper backup strategy for `/opt/exist/data`
   - Consider network isolation (Docker networks, firewall rules)
   - Review eXist-DB security settings in production

**Note:** `EXIST_ENV="development"` is required for RESTXQ registration. For production hardening, configure eXist-DB permissions after deployment rather than switching to production mode.

### Data Updates

To update the MEI data in the container:

```bash
# Rebuild image (fetches latest data from GitHub)
docker build -t beethovens-werkstatt-api:latest .

# Deploy updated image
docker stop bw-api && docker rm bw-api
docker run -d --name bw-api -p 8080:8080 beethovens-werkstatt-api:latest
```

### Docker Compose

Example `docker-compose.yml`:

```yaml
version: '3.8'

services:
  api:
    build: .
    image: beethovens-werkstatt-api:latest
    container_name: bw-api
    ports:
      - "8080:8080"
    environment:
      - EXIST_PASSWORD=change-me
      - EXIST_ENV=development
    restart: unless-stopped
    volumes:
      - exist-data:/opt/exist/data
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/exist/restxq/iiif/documents.json"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 90s

volumes:
  exist-data:
```

## Troubleshooting

### Local Development

**"Data directory not found"**
```bash
npm run fetch-data
```

**"No eXist-DB configuration found"**
```bash
cp .existdb.json.template .existdb.json
# Edit with your credentials
```

**Watch mode not working**
- Ensure eXist-DB is running
- Verify `.existdb.json` credentials
- Check app is installed at `/db/apps/api`

### Docker Issues

**RESTXQ endpoints return 405 errors**
- Wait 90 seconds for full startup
- Check logs: `docker logs bw-api | grep "post-install"`
- Should see: "API post-install: Registered 7 RESTXQ modules"

**Container exits immediately**
```bash
# Check logs for errors
docker logs bw-api

# Common issue: port already in use
# Solution: use different port or stop conflicting container
docker run -d --name bw-api -p 8082:8080 beethovens-werkstatt-api
```

**Package too large / slow deployment**
- Normal: 54.48 MB package with full data
- Deployment takes 30-50 seconds
- Be patient during first startup

**Cannot access from host**
- Verify port mapping: `docker ps`
- Check firewall settings
- Try `http://localhost:8080` not `http://172.17.0.x`

**Data not appearing in API**
- Rebuild image to fetch latest data: `docker build -t beethovens-werkstatt-api .`
- Check data was included: `docker run --rm beethovens-werkstatt-api ls -lh /opt/exist/autodeploy/`
- Should show ~55MB .xar file

## Architecture Notes

### Decoupled Data Pipeline

Data fetching is separate from building:
- Enables CI/CD caching
- Faster development builds
- Independent data versioning

### Native Node.js Build

No build framework dependencies:
- Uses native `fs`, `child_process`, `path`
- Modern ES modules
- Minimal dependencies (3 total)

### Modern Tooling

- `@existdb/xst` - Modern eXist-DB CLI
- `archiver` - ZIP/XAR creation
- `chokidar` - File watching

### REST API Architecture

The API uses **RESTXQ** for declarative routing with REST annotations:

**All 44 endpoints migrated to RESTXQ modules:**
- `iiif-api.xqm` - IIIF Presentation API (5 endpoints)
- `module1-api.xqm` - Digital Edition (17 endpoints)
- `module2-api.xqm` - Analysis (13 endpoints)
- `module3-api.xqm` - Sketch Analysis (3 endpoints)
- `module4-api.xqm` - Engraving Comparison (2 endpoints)
- `services-api.xqm` - Context, EMA, File services (4 endpoints)

The controller.xql (375 lines) simply forwards requests to RESTXQ, down from 737 lines of pattern matching.

**Benefits of RESTXQ:**
- Declarative routing with annotations (`%rest:GET`, `%rest:path()`)
- Type safety with parameter declarations
- Cleaner code organization by module
- Easier to maintain and extend
- **OpenAPI 3.0 documentation** - Auto-generated from REST annotations

### API Documentation

**Interactive documentation with Swagger UI:**
- Access at `/docs` endpoint (e.g., `http://localhost:8080/exist/apps/api/docs`)
- Try endpoints directly from the browser
- View request/response schemas

**OpenAPI 3.0 specification:**
- Available at `/openapi.json`
- Auto-generated from RESTXQ annotations
- Always up-to-date with code changes

## License

AGPL-3.0

