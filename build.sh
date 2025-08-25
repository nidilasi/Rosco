#!/bin/bash

# Rosco Command Line Build Script

set -e

echo "🔨 Building Rosco for macOS..."

# Check if we have xcodebuild
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Error: xcodebuild not found. Please install Xcode or Xcode Command Line Tools."
    echo "   Install Xcode from the App Store, then run:"
    echo "   sudo xcode-select --install"
    exit 1
fi

# Clean and build the project
echo "🔒 Building with code signing for macOS 15.4+ MediaRemote permissions..."
xcodebuild clean build \
    -project Rosco.xcodeproj \
    -scheme Rosco \
    -configuration Release \
    -derivedDataPath ./build

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ Build completed successfully!"
    echo ""
    echo "📦 App built at: ./build/Build/Products/Release/Rosco.app"
    echo ""
    echo "🚀 To run Rosco:"
    echo "   ./run.sh"
    echo ""
    echo "🔗 Or run directly:"
    echo "   open ./build/Build/Products/Release/Rosco.app"
else
    echo "❌ Build failed!"
    exit 1
fi
