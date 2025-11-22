# Beethovens Werkstatt API

This is the main data API of the Beethovens Werkstatt project. It provides access to MEI-encoded music data through various modules, with support for IIIF, genetic editions, and comparative analysis.

## Prerequisites

- Node.js 18 or later
- Git
- Local eXist-DB instance (for development)

## Quick Start

```bash
# Install dependencies
npm install

# Configure eXist-DB connection
cp .existdb.json.template .existdb.json
# Edit .existdb.json with your password

# Fetch data and build
npm run build:full

# Create distribution package
npm run package
```

## Available Commands

### Data Management

```bash
npm run fetch-data        # Clone/update data repositories
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

### Packaging & Distribution

```bash
npm run package           # Create .xar file
npm run dist              # Build + package (production)
npm run dist:full         # Fetch data + build + package
```

### Development

```bash
npm run watch             # Watch files and auto-deploy to eXist-DB
```

### Deployment (xst)

```bash
npm run deploy            # Deploy entire build/
npm run deploy:xql        # Deploy XQuery scripts only
npm run deploy:xqm        # Deploy XQuery modules only
npm run deploy:xslt       # Deploy XSLT only
npm run deploy:controller # Deploy controller only
npm run install:xar       # Install .xar to eXist-DB
```

## Project Structure

```
source/
├── eXist-db/        # eXist-DB configuration
├── xql/             # XQuery endpoints
├── xqm/             # XQuery modules
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
docker run -d --name bw-api -p 8080:8080 beethovens-werkstatt-api

# Start on different port (e.g., 8082)
docker run -d --name bw-api -p 8082:8080 beethovens-werkstatt-api

# With custom admin password
docker run -d --name bw-api \
  -p 8080:8080 \
  -e EXIST_PASSWORD="your-secure-password" \
  beethovens-werkstatt-api
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
| `EXIST_PASSWORD` | `admin123` | Admin password (⚠️ **change for production!**) |

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

For production, customize the Dockerfile:

```dockerfile
# Change admin password (line 38)
ENV EXIST_PASSWORD="your-secure-password"

# Consider switching to production mode (requires proper permissions)
ENV EXIST_ENV="production"
```

**Security notes:**
- Change `EXIST_PASSWORD` before deploying
- Use Docker secrets for sensitive data in orchestration systems
- Consider using a reverse proxy (nginx, traefik) for SSL/TLS
- Set up proper backup strategy for `/opt/exist/data`

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