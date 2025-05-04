#!/bin/bash

# Fail on error
set -e

echo "🔧 Cloning Flutter..."
git clone https://github.com/flutter/flutter.git -b stable

# Add Flutter to PATH
export PATH="$PATH:`pwd`/flutter/bin"

echo "🛠️ Running flutter doctor..."
flutter doctor

echo "🌐 Enabling web support..."
flutter config --enable-web

echo "📦 Getting dependencies..."
flutter pub get

echo "🚀 Building Flutter web..."
flutter build web
