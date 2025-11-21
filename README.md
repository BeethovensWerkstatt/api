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

The included Dockerfile builds the API:

```bash
docker build -t beethovens-werkstatt-api .
```

## Troubleshooting

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

## License

AGPL-3.0