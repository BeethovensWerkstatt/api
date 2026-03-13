import fs from 'fs/promises'
import path from 'path'
import archiver from 'archiver'
import { createWriteStream, existsSync } from 'fs'
import { getPackageJson } from './utils.js'

/**
 * Package script - creates XAR distribution file
 *
 * This script creates a .xar file (ZIP archive) from the build directory.
 *
 * Usage:
 *   node scripts/package.js
 */

const BUILD_DIR = 'build'
const DIST_DIR = 'dist'

// Read the resolved version from the built expath-pkg.xml so the .xar filename
// always matches the version inside (including any dev timestamp suffix added
// by build.js for local builds).
async function getBuiltVersion (fallback) {
  try {
    const content = await fs.readFile(path.join(BUILD_DIR, 'expath-pkg.xml'), 'utf8')
    const match = content.match(/<package[^>]+version="([^"]+)"/)

    return match ? match[1] : fallback
  } catch {
    return fallback
  }
}

// Remove any previously generated .xar files for this package so only the
// latest build is present in dist/ (prevents stale packages accumulating).
async function cleanDist (name) {
  try {
    const entries = await fs.readdir(DIST_DIR)
    for (const entry of entries) {
      if (entry.startsWith(`${name}-`) && entry.endsWith('.xar')) {
        await fs.unlink(path.join(DIST_DIR, entry))
        console.log(`  Removed old package: ${entry}`)
      }
    }
  } catch {
    // dist/ may not exist yet; createXar will handle that
  }
}

async function createXar () {
  const packageJson = await getPackageJson()
  const name = packageJson.name

  await cleanDist(name)

  const version = await getBuiltVersion(packageJson.version)
  const xarFileName = `${name}-${version}.xar`
  const xarPath = path.join(DIST_DIR, xarFileName)

  // Ensure dist directory exists
  await fs.mkdir(DIST_DIR, { recursive: true })

  // Verify build directory exists
  if (!existsSync(BUILD_DIR)) {
    console.error('❌ Error: Build directory not found!')
    console.error('Please run: npm run build')
    process.exit(1)
  }

  console.log(`Creating XAR package: ${xarFileName}...`)

  return new Promise((resolve, reject) => {
    const output = createWriteStream(xarPath)
    const archive = archiver('zip', {
      zlib: { level: 9 } // Maximum compression
    })

    output.on('close', () => {
      const sizeInMB = (archive.pointer() / 1024 / 1024).toFixed(2)
      console.log(`✓ Created ${xarFileName} (${sizeInMB} MB)`)
      resolve(xarPath)
    })

    archive.on('error', (err) => {
      reject(err)
    })

    archive.on('warning', (err) => {
      if (err.code === 'ENOENT') {
        console.warn('Warning:', err.message)
      } else {
        reject(err)
      }
    })

    // Pipe archive data to the file
    archive.pipe(output)

    // Add all files from build directory, excluding .git directories
    archive.glob('**/*', {
      cwd: BUILD_DIR,
      ignore: ['**/.git/**', '**/.git']
    })

    // Finalize the archive
    archive.finalize()
  })
}

async function main () {
  console.log('Packaging API for distribution...\n')

  try {
    const xarPath = await createXar()

    console.log('\n✓ Package complete!')
    console.log(`  Output: ${xarPath}`)
  } catch (error) {
    console.error('\n❌ Packaging failed:', error.message)
    process.exit(1)
  }
}

main()
