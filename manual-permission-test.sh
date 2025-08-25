#!/bin/bash

echo "🔧 Manual Permission Setup Test for Rosco"
echo ""
echo "The permission dialog doesn't appear because the app is adhoc-signed."
echo "But we can manually enable it in System Settings!"
echo ""
echo "📋 Manual Steps:"
echo "1. 🚀 First, run Rosco once so macOS knows about it:"
echo "   ./build/Build/Products/Release/Rosco.app/Contents/MacOS/Rosco &"
echo "   ROSCO_PID=\$!"
echo ""
echo "2. ⚙️  Open System Settings:"
echo "   open 'x-apple.systempreferences:com.apple.preference.security?Privacy_Media'"
echo ""
echo "3. 🔍 Look for 'Rosco' in the Media & Apple Music section"
echo "   - If you see it: Enable the toggle"
echo "   - If you don't see it: The app needs to request permission first"
echo ""
echo "4. 🔄 Restart Rosco after enabling permission"
echo ""
echo "Let's try this process now..."
echo ""

# Run Rosco in background
echo "Starting Rosco..."
./build/Build/Products/Release/Rosco.app/Contents/MacOS/Rosco &
ROSCO_PID=$!

echo "✅ Rosco started with PID: $ROSCO_PID"
echo ""

# Wait a moment for it to initialize
echo "⏳ Waiting 3 seconds for Rosco to initialize..."
sleep 3

# Open System Settings
echo "🔧 Opening Media & Apple Music privacy settings..."
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Media"

echo ""
echo "📋 Now check System Settings:"
echo "  • Look for 'Rosco' in the list"
echo "  • Enable the toggle if you see it"
echo "  • If you don't see Rosco, it means the permission request isn't working"
echo ""
echo "💡 After enabling permission, kill Rosco and restart:"
echo "   kill $ROSCO_PID"
echo "   ./run.sh"
echo ""
echo "🔍 You can also check if Rosco appears in the list with:"
echo "   sqlite3 ~/Library/Application Support/com.apple.TCC/TCC.db \"SELECT * FROM access WHERE service='kTCCServiceMediaLibrary';\""
