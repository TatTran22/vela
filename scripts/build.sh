#!/bin/bash
set -euo pipefail

echo "=== Building FinanceApp ==="

echo "Building iOS target..."
xcodebuild -scheme FinanceApp-iOS -destination 'platform=iOS Simulator,name=iPhone 16' build

echo "Building macOS target..."
xcodebuild -scheme FinanceApp-macOS -destination 'platform=macOS' build

echo "=== Build Complete ==="
