#!/bin/bash
echo "Installing Flutter directly via Git..."
git clone https://github.com/flutter/flutter.git -b stable
export PATH="`pwd`/flutter/bin:$PATH"
flutter config --no-analytics
flutter doctor

# We must CD into the subfolder because Vercel starts at the root
cd flare_dating_app || exit 1

echo "Fetching dependencies..."
flutter pub get

echo "Building web app for production (Forced HTML Renderer)..."
# Using --web-renderer html helps load large assets/images more reliably on web
flutter build web --release --web-renderer html
