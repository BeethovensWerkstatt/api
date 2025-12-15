import fs from 'fs/promises';
import path from 'path';
import { execSync } from 'child_process';

/**
 * Get the current git branch name
 * Supports GitHub Actions via GITHUB_REF_NAME environment variable
 */
export function getGitBranch() {
  // First check for GitHub Actions environment variable
  if (process.env.GITHUB_REF_NAME) {
    return process.env.GITHUB_REF_NAME;
  }
  
  // Fall back to git command
  try {
    return execSync('git rev-parse --abbrev-ref HEAD', { encoding: 'utf8' }).trim();
  } catch (error) {
    console.warn('Warning: Could not determine git branch, using "main"');
    return 'main';
  }
}

/**
 * Get short git commit hash
 */
export function getGitShortHash() {
  try {
    return execSync('git rev-parse --short HEAD', { encoding: 'utf8' }).trim();
  } catch (error) {
    return 'unknown';
  }
}

/**
 * Get git remote URL
 */
export function getGitRemoteUrl() {
  try {
    return execSync('git config --get remote.origin.url', { encoding: 'utf8' }).trim();
  } catch (error) {
    return '';
  }
}

/**
 * Check if git working directory is dirty
 */
export function isGitDirty() {
  try {
    const status = execSync('git status --porcelain', { encoding: 'utf8' });
    return status.length > 0;
  } catch (error) {
    return false;
  }
}

/**
 * Copy file and ensure directory exists
 */
export async function copyFile(src, dest) {
  await fs.mkdir(path.dirname(dest), { recursive: true });
  await fs.copyFile(src, dest);
}

/**
 * Copy directory recursively
 */
export async function copyDir(src, dest) {
  await fs.mkdir(dest, { recursive: true });
  const entries = await fs.readdir(src, { withFileTypes: true });

  for (const entry of entries) {
    const srcPath = path.join(src, entry.name);
    const destPath = path.join(dest, entry.name);

    if (entry.isDirectory()) {
      await copyDir(srcPath, destPath);
    } else {
      await copyFile(srcPath, destPath);
    }
  }
}

/**
 * Replace template strings in file content
 */
export function replaceTemplateStrings(content, replacements) {
  let result = content;
  for (const [key, value] of Object.entries(replacements)) {
    result = result.replace(new RegExp(`\\$\\$${key}\\$\\$`, 'g'), value);
  }
  return result;
}

/**
 * Process file with template replacements
 */
export async function processTemplate(srcPath, destPath, replacements) {
  let content = await fs.readFile(srcPath, 'utf8');
  content = replaceTemplateStrings(content, replacements);
  await fs.mkdir(path.dirname(destPath), { recursive: true });
  await fs.writeFile(destPath, content, 'utf8');
}

/**
 * Delete directory recursively
 */
export async function deleteDir(dirPath) {
  try {
    await fs.rm(dirPath, { recursive: true, force: true });
  } catch (error) {
    // Ignore errors if directory doesn't exist
  }
}

/**
 * Check if file/directory exists
 */
export async function exists(filePath) {
  try {
    await fs.access(filePath);
    return true;
  } catch {
    return false;
  }
}

/**
 * Get package.json as object
 */
export async function getPackageJson() {
  const content = await fs.readFile('package.json', 'utf8');
  return JSON.parse(content);
}

/**
 * Format date as ISO UTC DateTime
 */
export function formatISODateTime(date = new Date()) {
  return date.toISOString();
}
