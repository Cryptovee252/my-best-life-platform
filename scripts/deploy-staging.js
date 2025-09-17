#!/usr/bin/env node

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

console.log('🚀 Deploying to staging environment...\n');

try {
  // 1. Build the project
  console.log('📦 Building project...');
  execSync('npm run build', { stdio: 'inherit' });

  // 2. Run tests
  console.log('🧪 Running tests...');
  execSync('npm test', { stdio: 'inherit' });

  // 3. Commit changes to git
  console.log('📝 Committing changes...');
  execSync('git add .', { stdio: 'inherit' });
  execSync('git commit -m "Deploy: Staging update $(date)"', { stdio: 'inherit' });

  // 4. Push to staging branch
  console.log('📤 Pushing to staging branch...');
  execSync('git push origin staging', { stdio: 'inherit' });

  // 5. Deploy to VPS staging
  console.log('🌐 Deploying to VPS staging...');
  execSync('ssh your-vps "cd /path/to/staging && git pull origin staging && npm install && npm run build"', { stdio: 'inherit' });

  console.log('✅ Staging deployment completed successfully!');
  console.log('🔗 Staging URL: https://staging.yourdomain.com');

} catch (error) {
  console.error('❌ Deployment failed:', error.message);
  process.exit(1);
}
