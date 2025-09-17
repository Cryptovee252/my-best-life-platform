# Git Workflow for HelpMyBestLife Platform

## Branch Strategy

- **main**: Production-ready code
- **staging**: Pre-production testing
- **develop**: Integration branch for features
- **feature/***: Individual feature branches

## Development Workflow

### 1. Local Development
```bash
# Start local development
npm run dev

# Make your changes locally
# Test everything works
```

### 2. Commit Changes
```bash
# Add changes
git add .

# Commit with descriptive message
git commit -m "feat: add new feature description"

# Push to feature branch
git push origin feature/your-feature-name
```

### 3. Deploy to Staging
```bash
# Deploy to staging for testing
npm run deploy:staging
```

### 4. Deploy to Production
```bash
# Deploy to production
npm run deploy:production
```

## Commit Message Convention

Use conventional commits:
- `feat:` New features
- `fix:` Bug fixes
- `docs:` Documentation changes
- `style:` Code style changes
- `refactor:` Code refactoring
- `test:` Adding tests
- `chore:` Maintenance tasks

Examples:
- `feat: add user authentication`
- `fix: resolve database connection issue`
- `docs: update API documentation`

## Automated Deployment

The deployment scripts automatically:
1. Build the project
2. Run tests
3. Create backups
4. Commit changes
5. Push to appropriate branch
6. Deploy to VPS

## Rollback Strategy

If deployment fails:
1. Check the backup created before deployment
2. Use git to revert to previous commit
3. Redeploy from stable state
