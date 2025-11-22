import fs from 'fs/promises';
import path from 'path';
import { existsSync } from 'fs';
import {
  copyDir,
  processTemplate,
  deleteDir,
  exists,
  getPackageJson,
  formatISODateTime,
  getGitBranch
} from './utils.js';

/**
 * Build script for eXist-DB package
 * 
 * This script:
 * 1. Cleans the build directory
 * 2. Copies eXist-DB structure files with template replacements
 * 3. Copies XQuery files (xql, xqm) with template replacements
 * 4. Copies XSLT files
 * 5. Copies HTML files
 * 6. Verifies data directory exists
 * 
 * Usage:
 *   node scripts/build.js
 *   node scripts/build.js --public  (for production with public base URI)
 */

const SOURCE_DIR = 'source';
const BUILD_DIR = 'build';

async function clean() {
  console.log('Cleaning build directory...');
  
  // Keep data directories if they exist
  const keepDirs = ['data', 'data-cache'];
  const buildExists = await exists(BUILD_DIR);
  
  if (buildExists) {
    const entries = await fs.readdir(BUILD_DIR);
    for (const entry of entries) {
      if (!keepDirs.includes(entry)) {
        await deleteDir(path.join(BUILD_DIR, entry));
      }
    }
  }
  
  console.log('✓ Cleaned build directory');
}

async function getTemplateReplacements(isPublic = false) {
  const packageJson = await getPackageJson();
  const branch = getGitBranch();
  
  // Determine target URL based on environment
  let deployTarget;
  if (isPublic) {
    deployTarget = branch === 'main' 
      ? 'https://api.beethovens-werkstatt.de' 
      : 'https://dev-api.beethovens-werkstatt.de';
  } else {
    deployTarget = 'http://localhost:8080/exist/apps/api';
  }
  
  return {
    deployed: formatISODateTime(),
    version: packageJson.version,
    desc: packageJson.description,
    license: packageJson.license,
    abbrev: packageJson.name,
    deployTarget
  };
}

async function buildExistStructure(replacements) {
  console.log('Building eXist-DB structure...');
  
  const existFiles = [
    'collection.xconf',
    'controller.xql',
    'expath-pkg.xml',
    'pre-install.xql',
    'post-install.xql',
    'repo.xml'
  ];
  
  for (const file of existFiles) {
    const srcPath = path.join(SOURCE_DIR, 'eXist-db', file);
    const destPath = path.join(BUILD_DIR, file);
    
    if (await exists(srcPath)) {
      await processTemplate(srcPath, destPath, replacements);
    }
  }
  
  console.log('✓ Built eXist-DB structure');
}

async function buildXQuery(replacements) {
  console.log('Building XQuery files...');
  
  // Build XQL files (no template replacement needed)
  const xqlSrc = path.join(SOURCE_DIR, 'xql');
  const xqlDest = path.join(BUILD_DIR, 'resources', 'xql');
  
  if (await exists(xqlSrc)) {
    await copyDir(xqlSrc, xqlDest);
  }
  
  // Build XQM files (with template replacement for deployTarget)
  const xqmSrc = path.join(SOURCE_DIR, 'xqm');
  const xqmDest = path.join(BUILD_DIR, 'resources', 'xqm');
  
  if (await exists(xqmSrc)) {
    await fs.mkdir(xqmDest, { recursive: true });
    
    // Process all files and subdirectories
    const processDir = async (srcDir, destDir) => {
      const entries = await fs.readdir(srcDir, { withFileTypes: true });
      
      for (const entry of entries) {
        const srcPath = path.join(srcDir, entry.name);
        const destPath = path.join(destDir, entry.name);
        
        if (entry.isDirectory()) {
          await fs.mkdir(destPath, { recursive: true });
          await processDir(srcPath, destPath);
        } else {
          await processTemplate(srcPath, destPath, replacements);
        }
      }
    };
    
    await processDir(xqmSrc, xqmDest);
  }
  
  console.log('✓ Built XQuery files');
}

async function buildXSLT() {
  console.log('Building XSLT files...');
  
  const xsltSrc = path.join(SOURCE_DIR, 'xslt');
  const xsltDest = path.join(BUILD_DIR, 'resources', 'xslt');
  
  if (await exists(xsltSrc)) {
    await copyDir(xsltSrc, xsltDest);
  }
  
  console.log('✓ Built XSLT files');
}

async function buildHTML() {
  console.log('Building HTML files...');
  
  const htmlSrc = path.join(SOURCE_DIR, 'html');
  const htmlDest = BUILD_DIR;
  
  if (await exists(htmlSrc)) {
    const files = await fs.readdir(htmlSrc);
    for (const file of files) {
      const srcPath = path.join(htmlSrc, file);
      const destPath = path.join(htmlDest, file);
      await fs.copyFile(srcPath, destPath);
    }
  }
  
  console.log('✓ Built HTML files');
}

async function verifyData() {
  console.log('Verifying data directories...');
  
  const dataDir = path.join(BUILD_DIR, 'data');
  
  if (!existsSync(dataDir)) {
    console.warn('\n⚠️  Warning: Data directory not found.');
    console.warn('The package will be built without sample data.');
    console.warn('To include data, run: npm run fetch-data\n');
    return;
  }
  
  console.log('✓ Data directories verified');
}

async function main() {
  const args = process.argv.slice(2);
  const isPublic = args.includes('--public');
  
  console.log(`Building API (${isPublic ? 'production' : 'local'} mode)...\n`);
  
  try {
    const replacements = await getTemplateReplacements(isPublic);
    
    await clean();
    await buildExistStructure(replacements);
    await buildXQuery(replacements);
    await buildXSLT();
    await buildHTML();
    await verifyData();
    
    console.log('\n✓ Build complete!');
    console.log(`  Build directory: ${BUILD_DIR}`);
    console.log(`  Deploy target: ${replacements.deployTarget}`);
    console.log(`  Version: ${replacements.version}`);
  } catch (error) {
    console.error('\n❌ Build failed:', error.message);
    process.exit(1);
  }
}

main();
