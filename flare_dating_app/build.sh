#!/bin/bash
echo "Installing Flutter directly via Git..."
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

echo "Fetching dependencies..."
flutter pub get

echo "Building web app for production..."
flutter build web --release
