#!/bin/bash

# Asset Version Comparison Script
# This script compares assets between GitHub, local, and VPS to identify the latest versions

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

echo "🔍 ASSET VERSION COMPARISON"
echo "============================"
echo "Date: $(date)"
echo ""

# Configuration
LOCAL_MAIN_DIR="/Users/v./Documents/New/HelpMyBestLife"
LOCAL_BACKUP_DIR="/Users/v./Documents/New/HelpMyBestLife-Complete-Backup-20250814-172530/HelpMyBestLife"
VPS_HOST="147.93.47.43"
VPS_USER="root"
VPS_ASSETS_DIR="/var/www/mybestlife"

# Function to get file info
get_file_info() {
    local file_path="$1"
    if [ -f "$file_path" ]; then
        local size=$(stat -f%z "$file_path" 2>/dev/null || stat -c%s "$file_path" 2>/dev/null || echo "unknown")
        local modified=$(stat -f%m "$file_path" 2>/dev/null || stat -c%Y "$file_path" 2>/dev/null || echo "unknown")
        local date_str=$(date -r "$modified" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "unknown")
        echo "$size|$date_str|$modified"
    else
        echo "missing|missing|0"
    fi
}

# Function to compare directories
compare_directories() {
    local dir1="$1"
    local dir2="$2"
    local name1="$3"
    local name2="$4"
    
    print_status "Comparing $name1 vs $name2..."
    
    if [ ! -d "$dir1" ]; then
        print_error "$name1 directory not found: $dir1"
        return 1
    fi
    
    if [ ! -d "$dir2" ]; then
        print_error "$name2 directory not found: $dir2"
        return 1
    fi
    
    echo ""
    echo "📁 DIRECTORY COMPARISON: $name1 vs $name2"
    echo "=========================================="
    
    # Compare key files
    local key_files=(
        "package.json"
        "app.json"
        "tsconfig.json"
        "app/_layout.tsx"
        "app/(tabs)/index.tsx"
        "components/UserContext.tsx"
        "components/CommitmentContext.tsx"
        "hostinger-deploy/index.html"
        "dist/index.html"
    )
    
    for file in "${key_files[@]}"; do
        local file1="$dir1/$file"
        local file2="$dir2/$file"
        
        local info1=$(get_file_info "$file1")
        local info2=$(get_file_info "$file2")
        
        local size1=$(echo "$info1" | cut -d'|' -f1)
        local date1=$(echo "$info1" | cut -d'|' -f2)
        local mod1=$(echo "$info1" | cut -d'|' -f3)
        
        local size2=$(echo "$info2" | cut -d'|' -f1)
        local date2=$(echo "$info2" | cut -d'|' -f2)
        local mod2=$(echo "$info2" | cut -d'|' -f3)
        
        echo ""
        echo "📄 $file"
        echo "   $name1: $size1 bytes, $date1"
        echo "   $name2: $size2 bytes, $date2"
        
        if [ "$mod1" = "0" ] && [ "$mod2" = "0" ]; then
            echo "   Status: ❌ Missing in both"
        elif [ "$mod1" = "0" ]; then
            echo "   Status: ⚠️  Only in $name2"
        elif [ "$mod2" = "0" ]; then
            echo "   Status: ⚠️  Only in $name1"
        elif [ "$mod1" -gt "$mod2" ]; then
            echo "   Status: ✅ $name1 is newer"
        elif [ "$mod2" -gt "$mod1" ]; then
            echo "   Status: ✅ $name2 is newer"
        else
            echo "   Status: ✅ Same version"
        fi
    done
}

# Function to check VPS files
check_vps_files() {
    print_status "Checking VPS files..."
    
    if ! ssh -o ConnectTimeout=10 -o BatchMode=yes $VPS_USER@$VPS_HOST "echo 'VPS connection successful'" 2>/dev/null; then
        print_error "Cannot connect to VPS. Skipping VPS comparison."
        return 1
    fi
    
    echo ""
    echo "🖥️  VPS FILE CHECK"
    echo "=================="
    
    # Check key files on VPS
    local key_files=(
        "package.json"
        "app.json"
        "tsconfig.json"
        "app/_layout.tsx"
        "app/(tabs)/index.tsx"
        "components/UserContext.tsx"
        "components/CommitmentContext.tsx"
        "hostinger-deploy/index.html"
        "dist/index.html"
    )
    
    for file in "${key_files[@]}"; do
        local vps_file="$VPS_ASSETS_DIR/$file"
        
        echo ""
        echo "📄 $file"
        
        # Check if file exists on VPS
        local vps_info=$(ssh $VPS_USER@$VPS_HOST "
            if [ -f '$vps_file' ]; then
                size=\$(stat -c%s '$vps_file' 2>/dev/null || echo 'unknown')
                modified=\$(stat -c%Y '$vps_file' 2>/dev/null || echo '0')
                date_str=\$(date -d @\$modified '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo 'unknown')
                echo \"\$size|\$date_str|\$modified\"
            else
                echo 'missing|missing|0'
            fi
        ")
        
        local vps_size=$(echo "$vps_info" | cut -d'|' -f1)
        local vps_date=$(echo "$vps_info" | cut -d'|' -f2)
        local vps_mod=$(echo "$vps_info" | cut -d'|' -f3)
        
        echo "   VPS: $vps_size bytes, $vps_date"
        
        if [ "$vps_mod" = "0" ]; then
            echo "   Status: ❌ Missing on VPS"
        else
            echo "   Status: ✅ Exists on VPS"
        fi
    done
}

# Function to check deployment packages
check_deployment_packages() {
    print_status "Checking deployment packages..."
    
    echo ""
    echo "📦 DEPLOYMENT PACKAGES"
    echo "======================"
    
    # Check hostinger-deploy
    if [ -d "$LOCAL_MAIN_DIR/hostinger-deploy" ]; then
        local count=$(find "$LOCAL_MAIN_DIR/hostinger-deploy" -type f | wc -l)
        echo "✅ Local hostinger-deploy: $count files"
    else
        echo "❌ Local hostinger-deploy: Not found"
    fi
    
    if [ -d "$LOCAL_BACKUP_DIR/hostinger-deploy" ]; then
        local count=$(find "$LOCAL_BACKUP_DIR/hostinger-deploy" -type f | wc -l)
        echo "✅ Backup hostinger-deploy: $count files"
    else
        echo "❌ Backup hostinger-deploy: Not found"
    fi
    
    # Check dist
    if [ -d "$LOCAL_MAIN_DIR/dist" ]; then
        local count=$(find "$LOCAL_MAIN_DIR/dist" -type f | wc -l)
        echo "✅ Local dist: $count files"
    else
        echo "❌ Local dist: Not found"
    fi
    
    if [ -d "$LOCAL_BACKUP_DIR/dist" ]; then
        local count=$(find "$LOCAL_BACKUP_DIR/dist" -type f | wc -l)
        echo "✅ Backup dist: $count files"
    else
        echo "❌ Backup dist: Not found"
    fi
}

# Function to check backend files
check_backend_files() {
    print_status "Checking backend files..."
    
    echo ""
    echo "🔧 BACKEND FILES"
    echo "================"
    
    local backend_dirs=(
        "/Users/v./Documents/New/backend"
        "/Users/v./Documents/New/HelpMyBestLife-Complete-Backup-20250814-172530/backend"
    )
    
    local backend_names=(
        "Local Backend"
        "Backup Backend"
    )
    
    for i in "${!backend_dirs[@]}"; do
        local dir="${backend_dirs[$i]}"
        local name="${backend_names[$i]}"
        
        if [ -d "$dir" ]; then
            local count=$(find "$dir" -name "*.js" -o -name "*.json" -o -name "*.prisma" | wc -l)
            echo "✅ $name: $count files"
            
            # Check key backend files
            local key_files=(
                "app.js"
                "app-secure.js"
                "package.json"
                "prisma/schema.prisma"
                "middleware/security.js"
                "middleware/auth.js"
            )
            
            for file in "${key_files[@]}"; do
                if [ -f "$dir/$file" ]; then
                    local size=$(stat -f%z "$dir/$file" 2>/dev/null || stat -c%s "$dir/$file" 2>/dev/null || echo "unknown")
                    echo "   📄 $file: $size bytes"
                else
                    echo "   ❌ $file: Missing"
                fi
            done
        else
            echo "❌ $name: Not found"
        fi
    done
}

# Main execution
print_status "Starting asset comparison..."

# Step 1: Compare local directories
compare_directories "$LOCAL_MAIN_DIR" "$LOCAL_BACKUP_DIR" "Local Main" "Local Backup"

# Step 2: Check deployment packages
check_deployment_packages

# Step 3: Check backend files
check_backend_files

# Step 4: Check VPS files
check_vps_files

# Step 5: Summary
echo ""
echo "📊 SUMMARY"
echo "=========="
echo ""
echo "🎯 RECOMMENDATIONS:"
echo "==================="
echo ""
echo "1. **Use Local Main Directory** ($LOCAL_MAIN_DIR)"
echo "   - This appears to be your latest development version"
echo "   - Contains the most recent files and features"
echo "   - Has updated deployment packages"
echo ""
echo "2. **Sync to VPS**"
echo "   - Run: ./sync-latest-assets-to-vps.sh"
echo "   - This will sync your latest local assets to the VPS"
echo ""
echo "3. **Fix Database Issues**"
echo "   - Run: ./fix-all-assets-and-database.sh"
echo "   - This will fix the Prisma connection errors"
echo ""
echo "4. **Backup Strategy**"
echo "   - Keep the backup directory as a fallback"
echo "   - Create new backups before major changes"
echo ""
echo "🔧 NEXT STEPS:"
echo "=============="
echo ""
echo "1. Run the asset sync script:"
echo "   chmod +x sync-latest-assets-to-vps.sh"
echo "   ./sync-latest-assets-to-vps.sh"
echo ""
echo "2. Run the database fix script:"
echo "   chmod +x fix-all-assets-and-database.sh"
echo "   ./fix-all-assets-and-database.sh"
echo ""
echo "3. Test your website:"
echo "   https://mybestlifeapp.com"
echo ""
print_success "Asset comparison complete! 🔍"
