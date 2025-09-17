#!/usr/bin/env node

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

console.log('🚀 Deploying to production environment...\n');

try {
  // 1. Ensure we're on main branch
  console.log('🌿 Ensuring we\'re on main branch...');
  const currentBranch = execSync('git branch --show-current', { encoding: 'utf8' }).trim();
  if (currentBranch !== 'main') {
    console.log(`⚠️  Currently on ${currentBranch}, switching to main...`);
    execSync('git checkout main', { stdio: 'inherit' });
  }

  // 2. Pull latest changes
  console.log('📥 Pulling latest changes...');
  execSync('git pull origin main', { stdio: 'inherit' });

  // 3. Build the project
  console.log('📦 Building project...');
  execSync('npm run build', { stdio: 'inherit' });

  // 4. Run tests
  console.log('🧪 Running tests...');
  execSync('npm test', { stdio: 'inherit' });

  // 5. Create backup
  console.log('💾 Creating backup...');
  execSync('node scripts/backup.js', { stdio: 'inherit' });

  // 6. Commit changes to git
  console.log('📝 Committing changes...');
  execSync('git add .', { stdio: 'inherit' });
  execSync('git commit -m "Deploy: Production update $(date)"', { stdio: 'inherit' });

  // 7. Push to main branch
  console.log('📤 Pushing to main branch...');
  execSync('git push origin main', { stdio: 'inherit' });

  // 8. Deploy to VPS production
  console.log('🌐 Deploying to VPS production...');
  execSync('ssh your-vps "cd /path/to/production && git pull origin main && npm install --production && npm run build && pm2 restart all"', { stdio: 'inherit' });

  console.log('✅ Production deployment completed successfully!');
  console.log('🔗 Production URL: https://yourdomain.com');

} catch (error) {
  console.error('❌ Production deployment failed:', error.message);
  console.log('🔄 Rolling back...');
  // Add rollback logic here
  process.exit(1);
}
