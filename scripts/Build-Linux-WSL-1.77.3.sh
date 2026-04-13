#!/bin/bash
#
# Build Linux provider with proper executable permissions (must run in WSL/Linux)
#

set -e

VERSION="1.77.3"
OUTPUT_DIR="/mnt/c/source/terraform-provider-builds/v1.77.3-linux"
SOURCE_DIR="/mnt/c/source/vscodebuild/terraform-provider-genesyscloud-custom/terraform-provider-genesyscloud"

echo "============================================="
echo " Building Linux Provider v${VERSION}"
echo " (with proper Unix permissions)"
echo "============================================="
echo ""
echo "Source: $SOURCE_DIR"
echo "Output: $OUTPUT_DIR"
echo ""

# Navigate to source
cd "$SOURCE_DIR"

# Clean and create output directory
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"
echo "✅ Output directory ready"
echo ""

# Build for Linux
echo "============================================="
echo " Building for Linux (amd64)"
echo "============================================="
export GOOS=linux
export GOARCH=amd64
export CGO_ENABLED=0

echo "Building..."
START_TIME=$(date +%s)

go build -o "${OUTPUT_DIR}/terraform-provider-genesyscloud_v${VERSION}" \
    -ldflags "-s -w -X main.version=${VERSION}" .

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

if [ -f "${OUTPUT_DIR}/terraform-provider-genesyscloud_v${VERSION}" ]; then
    echo "✅ Linux build successful!"
    
    # Set executable permission
    chmod +x "${OUTPUT_DIR}/terraform-provider-genesyscloud_v${VERSION}"
    echo "✅ Executable permission set (+x)"
    
    # Verify permissions
    PERMS=$(ls -l "${OUTPUT_DIR}/terraform-provider-genesyscloud_v${VERSION}" | awk '{print $1}')
    echo "   Permissions: $PERMS"
    
    SIZE=$(ls -lh "${OUTPUT_DIR}/terraform-provider-genesyscloud_v${VERSION}" | awk '{print $5}')
    echo "   Size: $SIZE"
    echo "   Build time: ${DURATION}s"
    
    # Create zip while preserving permissions
    echo ""
    echo "Creating zip archive (preserving permissions)..."
    cd "$OUTPUT_DIR"
    zip -q "terraform-provider-genesyscloud_${VERSION}_linux_amd64.zip" \
        "terraform-provider-genesyscloud_v${VERSION}"
    
    if [ -f "terraform-provider-genesyscloud_${VERSION}_linux_amd64.zip" ]; then
        ZIP_SIZE=$(ls -lh "terraform-provider-genesyscloud_${VERSION}_linux_amd64.zip" | awk '{print $5}')
        echo "✅ Zip created: $ZIP_SIZE"
        
        # Verify zip contains executable permission
        echo ""
        echo "Verifying zip contents..."
        unzip -l "terraform-provider-genesyscloud_${VERSION}_linux_amd64.zip"
        
        echo ""
        echo "============================================="
        echo " Build Complete!"
        echo "============================================="
        echo ""
        echo "Output: ${OUTPUT_DIR}/terraform-provider-genesyscloud_${VERSION}_linux_amd64.zip"
        echo ""
        echo "✅ This zip file contains proper Unix executable permissions"
        echo ""
    else
        echo "❌ Failed to create zip"
        exit 1
    fi
else
    echo "❌ Linux build failed!"
    exit 1
fi
