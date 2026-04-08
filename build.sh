#!/bin/bash
echo "Installing Flutter directly via Git..."
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# We must CD into the subfolder because Vercel starts at the root
cd flare_dating_app || exit 1

echo "Fetching dependencies..."
flutter pub get

echo "Building web app for production..."
flutter build web --release
