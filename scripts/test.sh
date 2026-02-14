#!/bin/bash
set -euo pipefail

echo "=== Running Tests ==="

echo "Testing FinanceCore..."
swift test --package-path Packages/FinanceCore

echo "Testing FinanceData..."
swift test --package-path Packages/FinanceData

echo "Testing FinanceUI..."
swift test --package-path Packages/FinanceUI

echo "=== All Tests Complete ==="
