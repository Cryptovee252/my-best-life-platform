#!/usr/bin/env node

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

console.log('💾 Creating project backup...\n');

try {
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-').split('T')[0] + '-' + 
                   new Date().toISOString().replace(/[:.]/g, '-').split('T')[1].split('.')[0];
  
  const backupDir = path.join(__dirname, '..', 'backups', `backup-${timestamp}`);
  
  // Create backup directory
  fs.mkdirSync(backupDir, { recursive: true });
  
  // Copy essential files
  const filesToBackup = [
    'frontend',
    'backend',
    'package.json',
    'docker-compose.yml',
    'prisma',
    'scripts',
    'docs'
  ];
  
  filesToBackup.forEach(file => {
    const sourcePath = path.join(__dirname, '..', file);
    const destPath = path.join(backupDir, file);
    
    if (fs.existsSync(sourcePath)) {
      console.log(`📁 Backing up ${file}...`);
      execSync(`cp -r "${sourcePath}" "${destPath}"`, { stdio: 'inherit' });
    }
  });
  
  // Create backup manifest
  const manifest = {
    timestamp: new Date().toISOString(),
    version: require('../package.json').version,
    files: filesToBackup,
    gitCommit: execSync('git rev-parse HEAD', { encoding: 'utf8' }).trim(),
    gitBranch: execSync('git branch --show-current', { encoding: 'utf8' }).trim()
  };
  
  fs.writeFileSync(
    path.join(backupDir, 'backup-manifest.json'),
    JSON.stringify(manifest, null, 2)
  );
  
  console.log(`✅ Backup created successfully: ${backupDir}`);
  console.log(`📊 Backup size: ${getDirectorySize(backupDir)}`);
  
} catch (error) {
  console.error('❌ Backup failed:', error.message);
  process.exit(1);
}

function getDirectorySize(dirPath) {
  let size = 0;
  const files = fs.readdirSync(dirPath);
  
  files.forEach(file => {
    const filePath = path.join(dirPath, file);
    const stats = fs.statSync(filePath);
    
    if (stats.isDirectory()) {
      size += getDirectorySize(filePath);
    } else {
      size += stats.size;
    }
  });
  
  return formatBytes(size);
}

function formatBytes(bytes) {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}
