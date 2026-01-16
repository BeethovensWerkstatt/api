import { execSync } from 'child_process'
import { existsSync, writeFileSync, mkdirSync } from 'fs'
import { getGitBranch } from './utils.js'

/**
 * Fetch data from Git repositories
 *
 * This script clones or updates the data repositories needed for the API.
 * It supports multiple repositories and tracks their versions for build metadata.
 *
 * Branch Mapping:
 *   - data.git: API 'main' → data 'main', other branches → data 'dev'
 *   - data-cache.git: always uses 'main' branch
 *
 * Usage:
 *   node scripts/fetch-data.js              # Auto-detects data branch
 *   node scripts/fetch-data.js --branch dev # Override data branch
 *   node scripts/fetch-data.js --check      # Check if updates available (dry run)
 *   node scripts/fetch-data.js --clean      # Remove and re-clone all repos
 */

/**
 * Repository configuration
 * Add new data repositories here
 */
const REPOSITORIES = [
  {
    name: 'data',
    url: 'https://github.com/BeethovensWerkstatt/data.git',
    target: 'build/data',
    branchMap: { main: 'main', default: 'dev' },
    required: true
  },
  {
    name: 'data-cache',
    url: 'https://github.com/BeethovensWerkstatt/data-cache.git',
    target: 'build/data-cache',
    branchMap: { default: 'main' },
    required: false
  }
]

/**
 * Get the current commit hash of a repository
 */
function getGitCommit (repoDir) {
  try {
    return execSync(`git -C ${repoDir} rev-parse HEAD`, { encoding: 'utf-8' }).trim()
  } catch {
    return null
  }
}

/**
 * Get the current branch of a repository
 */
function getRepoBranch (repoDir) {
  try {
    return execSync(`git -C ${repoDir} rev-parse --abbrev-ref HEAD`, { encoding: 'utf-8' }).trim()
  } catch {
    return null
  }
}

/**
 * Check if updates are available for a repository
 */
function checkForUpdates (repoDir, branch) {
  try {
    execSync(`git -C ${repoDir} fetch origin ${branch}`, { stdio: 'pipe' })
    const local = execSync(`git -C ${repoDir} rev-parse HEAD`, { encoding: 'utf-8' }).trim()
    const remote = execSync(`git -C ${repoDir} rev-parse origin/${branch}`, { encoding: 'utf-8' }).trim()
    return local !== remote
  } catch {
    return true // Assume updates needed if check fails
  }
}

/**
 * Clone a repository
 */
function cloneRepo (repoUrl, targetDir, branch) {
  console.log(`  Cloning ${repoUrl} (branch: ${branch})...`)
  try {
    execSync(`git clone --depth 1 --branch ${branch} ${repoUrl} ${targetDir}`, {
      stdio: 'pipe'
    })
    console.log('  ✓ Cloned successfully')
    return true
  } catch (error) {
    console.error(`  ✗ Clone failed: ${error.message}`)
    return false
  }
}

/**
 * Update an existing repository
 */
function updateRepo (targetDir, branch) {
  console.log(`  Updating to latest ${branch}...`)
  try {
    execSync(`git -C ${targetDir} fetch origin && git -C ${targetDir} checkout ${branch} && git -C ${targetDir} pull origin ${branch}`, {
      stdio: 'pipe'
    })
    console.log('  ✓ Updated successfully')
    return true
  } catch (error) {
    console.error(`  ✗ Update failed: ${error.message}`)
    return false
  }
}

/**
 * Clone or update a repository
 */
function cloneOrUpdateRepo (repoUrl, targetDir, branch, forceClean = false) {
  if (forceClean && existsSync(targetDir)) {
    console.log('  Removing existing directory...')
    execSync(`rm -rf ${targetDir}`, { stdio: 'pipe' })
  }

  if (existsSync(targetDir)) {
    const currentBranch = getRepoBranch(targetDir)
    if (currentBranch !== branch) {
      console.log(`  Branch mismatch (${currentBranch} → ${branch}), re-cloning...`)
      execSync(`rm -rf ${targetDir}`, { stdio: 'pipe' })
      return cloneRepo(repoUrl, targetDir, branch)
    }
    return updateRepo(targetDir, branch)
  } else {
    return cloneRepo(repoUrl, targetDir, branch)
  }
}

/**
 * Determine which branch to use for a repository
 */
function determineBranch (repo, overrideBranch) {
  if (overrideBranch && repo.branchMap.default !== repo.branchMap.main) {
    return overrideBranch
  }

  const apiBranch = getGitBranch()
  return repo.branchMap[apiBranch] || repo.branchMap.default
}

/**
 * Generate data versions metadata
 */
function generateDataVersions () {
  const versions = {}

  for (const repo of REPOSITORIES) {
    if (existsSync(repo.target)) {
      versions[repo.name] = {
        commit: getGitCommit(repo.target),
        branch: getRepoBranch(repo.target),
        fetchedAt: new Date().toISOString()
      }
    }
  }

  return versions
}

/**
 * Write data versions to a metadata file
 */
function writeDataMetadata (versions) {
  const metadataDir = 'build'
  const metadataPath = `${metadataDir}/data-versions.json`

  if (!existsSync(metadataDir)) {
    mkdirSync(metadataDir, { recursive: true })
  }

  writeFileSync(metadataPath, JSON.stringify(versions, null, 2))
  console.log(`\n✓ Data versions written to ${metadataPath}`)
}

function main () {
  const args = process.argv.slice(2)

  // Parse arguments
  const checkOnly = args.includes('--check')
  const forceClean = args.includes('--clean')
  const branchIndex = args.indexOf('--branch')
  const overrideBranch = branchIndex !== -1 ? args[branchIndex + 1] : null

  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
  console.log('  Data Repository Manager')
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
  console.log(`  API Branch: ${getGitBranch()}`)
  console.log(`  Mode: ${checkOnly ? 'check' : forceClean ? 'clean' : 'update'}`)
  if (overrideBranch) console.log(`  Branch Override: ${overrideBranch}`)
  console.log('')

  const results = []

  for (const repo of REPOSITORIES) {
    const branch = determineBranch(repo, overrideBranch)
    console.log(`📦 ${repo.name} (${branch})`)
    console.log(`   Target: ${repo.target}`)

    if (checkOnly) {
      // Check mode: just report status
      if (existsSync(repo.target)) {
        const hasUpdates = checkForUpdates(repo.target, branch)
        console.log(`   Status: ${hasUpdates ? '⚠️  Updates available' : '✓ Up to date'}`)
        results.push({ repo: repo.name, hasUpdates })
      } else {
        console.log('   Status: ⚠️  Not cloned')
        results.push({ repo: repo.name, hasUpdates: true })
      }
    } else {
      // Update mode: clone or update
      const success = cloneOrUpdateRepo(repo.url, repo.target, branch, forceClean)
      if (!success && repo.required) {
        console.error(`\n✗ Failed to fetch required repository: ${repo.name}`)
        process.exit(1)
      }
      results.push({ repo: repo.name, success })
    }
    console.log('')
  }

  // Generate and save metadata
  if (!checkOnly) {
    const versions = generateDataVersions()
    writeDataMetadata(versions)
  }

  // Summary
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
  console.log('  Summary')
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
  for (const result of results) {
    if (checkOnly) {
      console.log(`  ${result.repo}: ${result.hasUpdates ? 'Updates available' : 'Up to date'}`)
    } else {
      console.log(`  ${result.repo}: ${result.success ? '✓' : '✗'}`)
    }
  }
  console.log('')
}

main()
