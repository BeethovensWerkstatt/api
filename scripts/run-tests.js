/**
 * XQSuite Test Runner
 *
 * This script runs XQSuite tests against a running eXist-db instance.
 * It connects to the database, executes the test runner, and parses results.
 *
 * Usage:
 *   node scripts/run-tests.js                    # Run all tests
 *   node scripts/run-tests.js --filter="iiif"   # Run filtered tests
 *   node scripts/run-tests.js --verbose         # Show detailed output
 *
 * Prerequisites:
 *   - eXist-db running (locally or Docker)
 *   - .existdb.json configured with connection details
 *   - API package deployed
 */

import { readFileSync, existsSync } from 'fs'
import { execSync } from 'child_process'

// ANSI color codes
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m'
}

// Parse command line arguments
const args = process.argv.slice(2)
const verbose = args.includes('--verbose') || args.includes('-v')
const filterArg = args.find(arg => arg.startsWith('--filter='))
const filter = filterArg ? filterArg.split('=')[1] : null

/**
 * Load eXist-db connection configuration
 */
function loadConfig () {
  const configPath = '.existdb.json'

  if (!existsSync(configPath)) {
    console.error(`${colors.red}Error: ${configPath} not found.${colors.reset}`)
    console.error('Copy .existdb.json.template to .existdb.json and configure it.')
    process.exit(1)
  }

  try {
    const config = JSON.parse(readFileSync(configPath, 'utf-8'))
    return config.servers?.localhost || config
  } catch (error) {
    console.error(`${colors.red}Error parsing ${configPath}:${colors.reset}`, error.message)
    process.exit(1)
  }
}

/**
 * Run XQSuite tests via xst
 */
function runTests () {
  console.log(`${colors.cyan}${colors.bright}🧪 Running XQSuite Tests${colors.reset}\n`)

  const config = loadConfig()
  const server = config.server || 'http://localhost:8082'

  console.log(`${colors.blue}Server:${colors.reset} ${server}`)
  console.log(`${colors.blue}Filter:${colors.reset} ${filter || 'none'}\n`)

  // Build the XQuery to run tests
  const testQuery = `
    xquery version "3.1";
    import module namespace test = "http://exist-db.org/xquery/xqsuite" 
        at "resource:org/exist/xquery/lib/xqsuite/xqsuite.xql";
    
    let $test-modules := (
        xs:anyURI("/db/apps/api/test/xqsuite/config-tests.xqm"),
        xs:anyURI("/db/apps/api/test/xqsuite/validation-tests.xqm"),
        xs:anyURI("/db/apps/api/test/xqsuite/iiif-tests.xqm")
    )
    
    let $functions := 
        for $module in $test-modules
        return inspect:module-functions($module)
    
    return test:suite($functions)
  `

  try {
    // Use xst to run the query
    const result = execSync(`xst --server localhost run -q '${testQuery.replace(/'/g, "\\'")}'`, {
      encoding: 'utf-8',
      stdio: ['pipe', 'pipe', 'pipe']
    })

    parseAndDisplayResults(result)
  } catch (error) {
    // Check if it's a test failure (xst might exit with error code)
    if (error.stdout) {
      parseAndDisplayResults(error.stdout)
    } else {
      console.error(`${colors.red}Error running tests:${colors.reset}`)
      console.error(error.message)

      if (error.message.includes('ECONNREFUSED')) {
        console.error(`\n${colors.yellow}Hint: Make sure eXist-db is running.${colors.reset}`)
        console.error('Start with: npm run docker:dev')
      }

      process.exit(1)
    }
  }
}

/**
 * Parse XQSuite XML results and display summary
 */
function parseAndDisplayResults (xmlResult) {
  // Simple regex-based parsing (for robustness without XML parser dependency)
  const testcases = xmlResult.match(/<testcase[^>]*>/g) || []
  const failures = xmlResult.match(/<failure[^>]*>[\s\S]*?<\/failure>/g) || []
  const errors = xmlResult.match(/<error[^>]*>[\s\S]*?<\/error>/g) || []
  const pending = xmlResult.match(/<testcase[^>]*pending="true"[^>]*>/g) || []

  const total = testcases.length
  const failed = failures.length + errors.length
  const skipped = pending.length
  const passed = total - failed - skipped

  console.log(`${colors.bright}Results:${colors.reset}`)
  console.log(`  ${colors.green}✓ Passed:${colors.reset}  ${passed}`)
  console.log(`  ${colors.red}✗ Failed:${colors.reset}  ${failed}`)
  console.log(`  ${colors.yellow}○ Skipped:${colors.reset} ${skipped}`)
  console.log(`  ${colors.blue}Total:${colors.reset}    ${total}\n`)

  // Show failures
  if (failed > 0) {
    console.log(`${colors.red}${colors.bright}Failures:${colors.reset}\n`)

    for (const failure of failures) {
      const message = failure.match(/>([^<]+)</)?.[1] || 'Unknown error'
      console.log(`  ${colors.red}✗${colors.reset} ${message}`)
    }

    for (const error of errors) {
      const message = error.match(/>([^<]+)</)?.[1] || 'Unknown error'
      console.log(`  ${colors.red}✗${colors.reset} ${message}`)
    }
    console.log()
  }

  // Verbose output
  if (verbose) {
    console.log(`${colors.cyan}Full output:${colors.reset}`)
    console.log(xmlResult)
  }

  // Exit code
  if (failed > 0) {
    console.log(`${colors.red}${colors.bright}Tests failed!${colors.reset}`)
    process.exit(1)
  } else {
    console.log(`${colors.green}${colors.bright}All tests passed!${colors.reset}`)
    process.exit(0)
  }
}

// Run
runTests()
