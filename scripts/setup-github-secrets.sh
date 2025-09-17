#!/bin/bash

# My Best Life - GitHub Secrets Setup Helper
# This script helps you configure GitHub secrets for automated deployment

set -e

echo "🔐 My Best Life - GitHub Secrets Setup"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if GitHub CLI is installed
check_gh_cli() {
    if ! command -v gh &> /dev/null; then
        print_error "GitHub CLI (gh) is not installed!"
        print_status "Installing GitHub CLI..."
        brew install gh
    fi
    
    # Check if user is authenticated
    if ! gh auth status &> /dev/null; then
        print_error "Not authenticated with GitHub!"
        print_status "Please run: gh auth login"
        exit 1
    fi
    
    print_success "GitHub CLI is ready!"
}

# Get repository info
get_repo_info() {
    REPO_URL=$(git remote get-url origin)
    REPO_NAME=$(basename "$REPO_URL" .git)
    REPO_OWNER=$(echo "$REPO_URL" | sed 's/.*github.com[:/]\([^/]*\)\/.*/\1/')
    
    print_status "Repository: $REPO_OWNER/$REPO_NAME"
}

# Interactive setup for Hostinger credentials
setup_hostinger_secrets() {
    print_status "Setting up Hostinger FTP credentials..."
    echo ""
    
    # Get FTP Host
    read -p "Enter your Hostinger FTP Host (e.g., ftp.yourdomain.com): " FTP_HOST
    if [ -z "$FTP_HOST" ]; then
        print_error "FTP Host cannot be empty!"
        exit 1
    fi
    
    # Get FTP Username
    read -p "Enter your Hostinger FTP Username: " FTP_USERNAME
    if [ -z "$FTP_USERNAME" ]; then
        print_error "FTP Username cannot be empty!"
        exit 1
    fi
    
    # Get FTP Password
    read -s -p "Enter your Hostinger FTP Password: " FTP_PASSWORD
    echo ""
    if [ -z "$FTP_PASSWORD" ]; then
        print_error "FTP Password cannot be empty!"
        exit 1
    fi
    
    print_status "Adding secrets to GitHub repository..."
    
    # Add secrets to GitHub
    gh secret set HOSTINGER_FTP_HOST --body "$FTP_HOST"
    gh secret set HOSTINGER_FTP_USERNAME --body "$FTP_USERNAME"
    gh secret set HOSTINGER_FTP_PASSWORD --body "$FTP_PASSWORD"
    
    print_success "Hostinger FTP secrets added to GitHub!"
}

# Optional: Setup additional secrets
setup_optional_secrets() {
    echo ""
    print_status "Optional: Additional secrets setup"
    echo ""
    
    read -p "Do you want to add database and JWT secrets? (y/n): " ADD_SECRETS
    
    if [[ $ADD_SECRETS =~ ^[Yy]$ ]]; then
        # Get Database URL
        read -p "Enter your PostgreSQL DATABASE_URL: " DB_URL
        if [ ! -z "$DB_URL" ]; then
            gh secret set HOSTINGER_DB_URL --body "$DB_URL"
            print_success "Database URL added!"
        fi
        
        # Get JWT Secret
        read -p "Enter your JWT Secret (or press Enter to generate): " JWT_SECRET
        if [ -z "$JWT_SECRET" ]; then
            JWT_SECRET=$(openssl rand -base64 32)
            print_status "Generated JWT Secret: $JWT_SECRET"
        fi
        gh secret set JWT_SECRET --body "$JWT_SECRET"
        print_success "JWT Secret added!"
    fi
}

# Verify secrets
verify_secrets() {
    print_status "Verifying secrets..."
    
    # List secrets
    echo ""
    print_status "Current secrets in repository:"
    gh secret list
    
    echo ""
    print_success "Secrets setup complete!"
}

# Create deployment test
create_deployment_test() {
    print_status "Creating test deployment..."
    
    # Create a simple test file
    echo "<!-- Test deployment - $(date) -->" > test-deployment.html
    git add test-deployment.html
    git commit -m "Test: automated deployment setup"
    git push origin main
    
    print_success "Test deployment triggered!"
    print_status "Check GitHub Actions tab to monitor deployment"
}

# Main setup process
main() {
    print_status "Starting GitHub secrets setup..."
    
    check_gh_cli
    get_repo_info
    setup_hostinger_secrets
    setup_optional_secrets
    verify_secrets
    
    echo ""
    print_success "🎉 GitHub secrets setup complete!"
    echo ""
    print_status "Next steps:"
    echo "1. Configure Hostinger Node.js settings"
    echo "2. Set up PostgreSQL database"
    echo "3. Test deployment by pushing changes"
    echo ""
    
    read -p "Do you want to trigger a test deployment now? (y/n): " TEST_DEPLOY
    
    if [[ $TEST_DEPLOY =~ ^[Yy]$ ]]; then
        create_deployment_test
    fi
    
    echo ""
    print_success "Setup complete! Your automated deployment is ready! 🚀"
}

# Run main function
main "$@"
