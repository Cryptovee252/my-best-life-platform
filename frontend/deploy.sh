#!/bin/bash

# HelpMyBestLife Deployment Script for Hostinger
# This script helps prepare and deploy your app to Hostinger

echo "🚀 HelpMyBestLife Deployment Script"
echo "=================================="

# Check if dist folder exists
if [ ! -d "dist" ]; then
    echo "❌ Error: dist folder not found!"
    echo "Please run 'npx expo export' first to build the web version."
    exit 1
fi

echo "✅ Build found in dist folder"
echo ""

# Create deployment package
echo "📦 Creating deployment package..."
DEPLOY_DIR="hostinger-deploy"
rm -rf $DEPLOY_DIR
mkdir $DEPLOY_DIR

# Copy all files from dist
cp -r dist/* $DEPLOY_DIR/

echo "✅ Deployment package created in: $DEPLOY_DIR"
echo ""

# Show file structure
echo "📁 Files ready for upload:"
ls -la $DEPLOY_DIR/
echo ""

echo "🎯 Next Steps:"
echo "1. Upload ALL contents from the '$DEPLOY_DIR' folder to your Hostinger public_html directory"
echo "2. Make sure to maintain the folder structure"
echo "3. Include the .htaccess file for proper routing"
echo "4. Test your website at https://yourdomain.com"
echo ""
echo "📖 For detailed instructions, see: deploy-to-hostinger.md"
echo ""
echo "🔗 Quick upload options:"
echo "- Use Hostinger File Manager (recommended)"
echo "- Use FTP client (FileZilla, WinSCP, etc.)"
echo "- Use Hostinger's drag-and-drop upload feature"
echo ""
echo "✅ Deployment package ready!"
