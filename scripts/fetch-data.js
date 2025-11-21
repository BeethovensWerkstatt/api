import { execSync } from 'child_process';
import { existsSync } from 'fs';
import { getGitBranch } from './utils.js';

/**
 * Fetch data from both data repositories
 * 
 * This script clones or updates the data and data-cache repositories
 * which are needed for building the API.
 * 
 * Branch Mapping:
 *   - data.git: API 'main' → data 'main', other API branches → data 'dev'
 *   - data-cache.git: always uses 'main' (only branch available)
 * 
 * Usage:
 *   node scripts/fetch-data.js              # Auto-detects data branch
 *   node scripts/fetch-data.js --branch dev # Override data branch (not data-cache)
 */

const DATA_REPO = 'https://github.com/BeethovensWerkstatt/data.git';
const DATA_CACHE_REPO = 'https://github.com/BeethovensWerkstatt/data-cache.git';
const DATA_DIR = 'build/data';
const DATA_CACHE_DIR = 'build/data-cache';

function cloneOrUpdateRepo(repoUrl, targetDir, branch) {
  if (existsSync(targetDir)) {
    console.log(`Updating existing repository in ${targetDir}...`);
    try {
      execSync(`cd ${targetDir} && git fetch origin && git checkout ${branch} && git pull origin ${branch}`, {
        stdio: 'inherit'
      });
      console.log(`✓ Updated ${targetDir}`);
    } catch (error) {
      console.error(`Error updating ${targetDir}:`, error.message);
      console.log('Removing and re-cloning...');
      execSync(`rm -rf ${targetDir}`, { stdio: 'inherit' });
      cloneRepo(repoUrl, targetDir, branch);
    }
  } else {
    cloneRepo(repoUrl, targetDir, branch);
  }
}

function cloneRepo(repoUrl, targetDir, branch) {
  console.log(`Cloning ${repoUrl} (branch: ${branch}) into ${targetDir}...`);
  try {
    execSync(`git clone --depth 1 --branch ${branch} ${repoUrl} ${targetDir}`, {
      stdio: 'inherit'
    });
    console.log(`✓ Cloned ${targetDir}`);
  } catch (error) {
    console.error(`Error cloning ${repoUrl}:`, error.message);
    process.exit(1);
  }
}

function mapApiBranchToDataBranch(apiBranch) {
  // Map API branch names to data branch names
  // Default to 'dev' for development branches, 'main' for main
  
  if (apiBranch === 'main') {
    return 'main';
  }
  
  // For any development/feature branch, use 'dev' data
  return 'dev';
}

function main() {
  // Get branch from command line or use current branch
  const args = process.argv.slice(2);
  const branchIndex = args.indexOf('--branch');
  
  let dataBranch;
  if (branchIndex !== -1 && args[branchIndex + 1]) {
    // Explicit branch provided
    dataBranch = args[branchIndex + 1];
  } else {
    // Map current API branch to appropriate data branch
    const apiBranch = getGitBranch();
    dataBranch = mapApiBranchToDataBranch(apiBranch);
    console.log(`API branch: ${apiBranch} → Using data branch: ${dataBranch}`);
  }

  console.log(`Fetching data repositories...\n`);

  // Clone or update data repository (uses mapped branch)
  console.log(`Data repo: branch ${dataBranch}`);
  cloneOrUpdateRepo(DATA_REPO, DATA_DIR, dataBranch);
  
  // Clone or update data-cache repository (always uses 'main')
  console.log(`Data-cache repo: branch main (always)`);
  cloneOrUpdateRepo(DATA_CACHE_REPO, DATA_CACHE_DIR, 'main');

  console.log('\n✓ Data fetch complete!');
  console.log(`  - ${DATA_DIR} (${dataBranch})`);
  console.log(`  - ${DATA_CACHE_DIR} (main)`);
}

main();
