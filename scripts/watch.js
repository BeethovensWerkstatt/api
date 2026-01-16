import chokidar from 'chokidar'
import { execSync } from 'child_process'
import path from 'path'
import { existsSync } from 'fs'

/**
 * Watch script - monitors source files and deploys changes to eXist-DB
 *
 * This script watches for changes in source files and automatically
 * rebuilds and deploys them to a local eXist-DB instance.
 *
 * Usage:
 *   node scripts/watch.js
 *
 * Requirements:
 *   - Local eXist-DB instance running
 *   - .existdb.json with connection details
 */

const SOURCE_DIR = 'source'
const CONFIG_FILE = '.existdb.json'

// Check if eXist-DB connection is configured
function checkExistConfig () {
  if (!existsSync(CONFIG_FILE)) {
    console.error('❌ Error: No eXist-DB configuration found!')
    console.error('Please create .existdb.json with your connection details.')
    console.error('Example:')
    console.error(JSON.stringify({
      servers: {
        localhost: {
          server: 'http://localhost:8082/exist',
          user: 'admin',
          password: 'admin123'
        }
      },
      sync: {
        server: 'localhost'
      }
    }, null, 2))
    process.exit(1)
  }
}

// Helper to run xst with config
function xst (args) {
  return `xst --config ${CONFIG_FILE} ${args}`
}

function deployXQuery (filePath) {
  console.log(`Deploying XQuery: ${filePath}`)
  try {
    // Build the specific file
    execSync('node scripts/build.js', { stdio: 'inherit' })

    // Deploy to eXist-DB using xst
    const relativePath = path.relative(SOURCE_DIR, filePath)
    let targetCollection

    if (relativePath.startsWith('xql/')) {
      targetCollection = '/db/apps/api/resources/xql/'
    } else if (relativePath.startsWith('xqm/')) {
      targetCollection = '/db/apps/api/resources/xqm/'
    }

    if (targetCollection) {
      const buildPath = path.join('build', 'resources', relativePath)
      // Get the directory from the relative path
      const relDir = path.dirname(relativePath)
      const actualTarget = `/db/apps/api/resources/${relDir}/`
      execSync(xst(`upload ${buildPath} ${actualTarget}`), { stdio: 'inherit' })
      console.log(`✓ Deployed ${relativePath}`)
    }
  } catch (error) {
    console.error(`Error deploying ${filePath}:`, error.message)
  }
}

function deployController () {
  console.log('Deploying controller.xql')
  try {
    execSync('node scripts/build.js', { stdio: 'inherit' })
    execSync(xst('upload build/controller.xql /db/apps/api/'), { stdio: 'inherit' })
    console.log('✓ Deployed controller.xql')
  } catch (error) {
    console.error('Error deploying controller:', error.message)
  }
}

function deployXSLT (filePath) {
  console.log(`Deploying XSLT: ${filePath}`)
  try {
    const relativePath = path.relative(path.join(SOURCE_DIR, 'xslt'), filePath)
    const buildPath = path.join('build', 'resources', 'xslt', relativePath)
    const relDir = path.dirname(relativePath)
    const targetCollection = relDir === '.'
      ? '/db/apps/api/resources/xslt/'
      : `/db/apps/api/resources/xslt/${relDir}/`

    execSync('node scripts/build.js', { stdio: 'inherit' })
    execSync(xst(`upload ${buildPath} ${targetCollection}`), { stdio: 'inherit' })
    console.log(`✓ Deployed ${relativePath}`)
  } catch (error) {
    console.error(`Error deploying ${filePath}:`, error.message)
  }
}

function deployHTML (filePath) {
  console.log(`Deploying HTML: ${filePath}`)
  try {
    const fileName = path.basename(filePath)
    const buildPath = path.join('build', fileName)
    const targetCollection = '/db/apps/api/'

    execSync('node scripts/build.js', { stdio: 'inherit' })
    execSync(xst(`upload ${buildPath} ${targetCollection}`), { stdio: 'inherit' })
    console.log(`✓ Deployed ${fileName}`)
  } catch (error) {
    console.error(`Error deploying ${filePath}:`, error.message)
  }
}

function main () {
  checkExistConfig()

  console.log('Starting file watcher...')
  console.log('Watching for changes in source files...\n')

  // Watch XQuery files
  const xqueryWatcher = chokidar.watch([
    `${SOURCE_DIR}/xql`,
    `${SOURCE_DIR}/xqm`
  ], {
    persistent: true,
    ignoreInitial: true,
    ignored: (path, stats) => stats?.isFile() && !(path.endsWith('.xql') || path.endsWith('.xqm'))
  })

  xqueryWatcher.on('change', deployXQuery)
  xqueryWatcher.on('add', deployXQuery)

  // Watch controller
  const controllerWatcher = chokidar.watch(
    `${SOURCE_DIR}/eXist-db/controller.xql`,
    {
      persistent: true,
      ignoreInitial: true
    }
  )

  controllerWatcher.on('change', deployController)

  // Watch XSLT files
  const xsltWatcher = chokidar.watch(
    `${SOURCE_DIR}/xslt`,
    {
      persistent: true,
      ignoreInitial: true,
      ignored: (path, stats) => stats?.isFile() && !path.endsWith('.xsl')
    }
  )

  xsltWatcher.on('change', deployXSLT)
  xsltWatcher.on('add', deployXSLT)

  // Watch HTML files
  const htmlWatcher = chokidar.watch(
    `${SOURCE_DIR}/html`,
    {
      persistent: true,
      ignoreInitial: true,
      ignored: (path, stats) => stats?.isFile() && !path.endsWith('.html')
    }
  )

  htmlWatcher.on('change', deployHTML)
  htmlWatcher.on('add', deployHTML)

  console.log('✓ Watching:')
  console.log('  - XQuery files (*.xql, *.xqm)')
  console.log('  - Controller (controller.xql)')
  console.log('  - XSLT files (*.xsl)')
  console.log('  - HTML files (*.html)')
  console.log('\nPress Ctrl+C to stop watching.\n')
}

main()
