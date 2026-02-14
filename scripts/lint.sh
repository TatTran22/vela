#!/bin/bash
set -euo pipefail

echo "=== Linting & Formatting ==="

echo "Running SwiftLint..."
swiftlint lint --strict

echo "Running SwiftFormat..."
swiftformat . --config .swiftformat

echo "=== Lint Complete ==="
