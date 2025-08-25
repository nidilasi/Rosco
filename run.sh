#!/bin/bash

# Rosco Command Line Runner Script

APP_PATH="./build/Build/Products/Release/Rosco.app"

# Check if the app exists
if [ ! -d "$APP_PATH" ]; then
    echo "❌ Rosco.app not found at: $APP_PATH"
    echo ""
    echo "🔨 Please build the app first:"
    echo "   ./build.sh"
    exit 1
fi

echo "🚀 Starting Rosco with debug output..."
echo "📍 Running from: $APP_PATH"
echo ""
echo "💡 Banner should appear at bottom of screen when music plays"
echo "🛑 Press Ctrl+C to stop"
echo ""
echo "Debug output:"
echo "----------------------------------------"

# Run the app directly to see debug output
"$APP_PATH/Contents/MacOS/Rosco"