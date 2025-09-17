#!/bin/bash

# Upload Scripts to VPS
# This script uploads the fix scripts to your VPS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

echo "📤 UPLOADING SCRIPTS TO VPS"
echo "============================"
echo "Date: $(date)"
echo ""

# Configuration
VPS_HOST="147.93.47.43"
VPS_USER="root"
LOCAL_SCRIPT_DIR="/Users/v./Documents/New"
VPS_SCRIPT_DIR="/root/scripts"

print_status "Configuration:"
echo "  VPS Host: $VPS_HOST"
echo "  VPS User: $VPS_USER"
echo "  Local Scripts: $LOCAL_SCRIPT_DIR"
echo "  VPS Scripts: $VPS_SCRIPT_DIR"
echo ""

# Step 1: Check if scripts exist locally
print_status "1. Checking local scripts..."
SCRIPTS=(
    "fix-all-assets-and-database.sh"
    "sync-latest-assets-to-vps.sh"
    "compare-asset-versions.sh"
)

for script in "${SCRIPTS[@]}"; do
    if [ -f "$LOCAL_SCRIPT_DIR/$script" ]; then
        print_success "Found: $script"
    else
        print_error "Missing: $script"
        exit 1
    fi
done

# Step 2: Test VPS connection
print_status "2. Testing VPS connection..."
if ! ssh -o ConnectTimeout=10 -o BatchMode=yes $VPS_USER@$VPS_HOST "echo 'VPS connection successful'" 2>/dev/null; then
    print_error "Cannot connect to VPS. Please check:"
    echo "  - VPS is running"
    echo "  - SSH key is configured"
    echo "  - Firewall allows SSH"
    echo "  - IP address is correct"
    echo ""
    echo "🔧 SSH SETUP HELP:"
    echo "=================="
    echo "If you need to set up SSH access:"
    echo ""
    echo "1. Generate SSH key (if you don't have one):"
    echo "   ssh-keygen -t rsa -b 4096 -C 'your-email@example.com'"
    echo ""
    echo "2. Copy your public key to VPS:"
    echo "   ssh-copy-id $VPS_USER@$VPS_HOST"
    echo ""
    echo "3. Or manually add your public key to VPS:"
    echo "   cat ~/.ssh/id_rsa.pub | ssh $VPS_USER@$VPS_HOST 'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys'"
    echo ""
    echo "4. Test connection:"
    echo "   ssh $VPS_USER@$VPS_HOST 'echo Connection successful'"
    exit 1
fi
print_success "VPS connection successful"

# Step 3: Create scripts directory on VPS
print_status "3. Creating scripts directory on VPS..."
ssh $VPS_USER@$VPS_HOST "mkdir -p $VPS_SCRIPT_DIR"
print_success "Scripts directory created"

# Step 4: Upload scripts
print_status "4. Uploading scripts to VPS..."

for script in "${SCRIPTS[@]}"; do
    print_status "Uploading $script..."
    scp "$LOCAL_SCRIPT_DIR/$script" "$VPS_USER@$VPS_HOST:$VPS_SCRIPT_DIR/"
    print_success "Uploaded: $script"
done

# Step 5: Make scripts executable on VPS
print_status "5. Making scripts executable on VPS..."
ssh $VPS_USER@$VPS_HOST "chmod +x $VPS_SCRIPT_DIR/*.sh"
print_success "Scripts made executable"

# Step 6: Verify upload
print_status "6. Verifying upload..."
ssh $VPS_USER@$VPS_HOST "ls -la $VPS_SCRIPT_DIR/"
print_success "Upload verification complete"

echo ""
print_success "Scripts uploaded successfully!"
echo ""
echo "✅ UPLOADED SCRIPTS:"
echo "===================="
echo "  ✅ fix-all-assets-and-database.sh"
echo "  ✅ sync-latest-assets-to-vps.sh"
echo "  ✅ compare-asset-versions.sh"
echo ""
echo "🚀 NEXT STEPS:"
echo "=============="
echo ""
echo "1. SSH into your VPS:"
echo "   ssh $VPS_USER@$VPS_HOST"
echo ""
echo "2. Navigate to scripts directory:"
echo "   cd $VPS_SCRIPT_DIR"
echo ""
echo "3. Run the database fix script:"
echo "   ./fix-all-assets-and-database.sh"
echo ""
echo "4. Run the asset sync script:"
echo "   ./sync-latest-assets-to-vps.sh"
echo ""
echo "5. Test your website:"
echo "   curl -f https://mybestlifeapp.com/api/health"
echo ""
echo "🔍 ALTERNATIVE METHODS:"
echo "========================"
echo ""
echo "If you prefer other methods:"
echo ""
echo "📋 Method 1: Manual Upload via SCP"
echo "  scp fix-all-assets-and-database.sh $VPS_USER@$VPS_HOST:/root/"
echo "  scp sync-latest-assets-to-vps.sh $VPS_USER@$VPS_HOST:/root/"
echo "  scp compare-asset-versions.sh $VPS_USER@$VPS_HOST:/root/"
echo ""
echo "📋 Method 2: Copy-Paste Method"
echo "  1. SSH into VPS: ssh $VPS_USER@$VPS_HOST"
echo "  2. Create script files: nano fix-all-assets-and-database.sh"
echo "  3. Copy and paste script content"
echo "  4. Save and make executable: chmod +x *.sh"
echo ""
echo "📋 Method 3: Direct Execution"
echo "  ssh $VPS_USER@$VPS_HOST 'bash -s' < fix-all-assets-and-database.sh"
echo ""
print_success "Upload complete! 🚀"
