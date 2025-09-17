#!/usr/bin/env node

const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

console.log('🚀 Starting HelpMyBestLife Local Development Environment...\n');

// Check if .env.local exists
const envPath = path.join(__dirname, '..', '.env.local');
if (!fs.existsSync(envPath)) {
  console.log('⚠️  .env.local not found. Creating from template...');
  const envExample = path.join(__dirname, '..', 'env.local.example');
  if (fs.existsSync(envExample)) {
    fs.copyFileSync(envExample, envPath);
    console.log('✅ Created .env.local from template');
  }
}

// Start Docker database
console.log('🐳 Starting PostgreSQL database...');
const dockerProcess = spawn('docker-compose', ['up', '-d', 'db'], {
  cwd: path.join(__dirname, '..'),
  stdio: 'inherit'
});

dockerProcess.on('close', (code) => {
  if (code === 0) {
    console.log('✅ Database started successfully\n');
    
    // Start backend
    console.log('🔧 Starting backend server...');
    const backendProcess = spawn('npm', ['run', 'dev:backend'], {
      cwd: path.join(__dirname, '..'),
      stdio: 'inherit',
      shell: true
    });

    // Start frontend
    console.log('🎨 Starting frontend development server...');
    const frontendProcess = spawn('npm', ['run', 'dev:frontend'], {
      cwd: path.join(__dirname, '..'),
      stdio: 'inherit',
      shell: true
    });

    // Handle cleanup
    process.on('SIGINT', () => {
      console.log('\n🛑 Shutting down development servers...');
      backendProcess.kill();
      frontendProcess.kill();
      process.exit(0);
    });
  } else {
    console.error('❌ Failed to start database');
    process.exit(1);
  }
});
