#!/bin/bash
# Link Checker Script
# Checks for broken links in README.md and reports findings

set -e

echo "🔍 Starting link check for README.md..."

# Check if lychee is available
if ! command -v lychee &> /dev/null; then
    echo "❌ lychee not found. Installing..."
    # Try to install via cargo if available
    if command -v cargo &> /dev/null; then
        cargo install lychee
    else
        echo "❌ Neither lychee nor cargo found. Please install lychee manually."
        exit 1
    fi
fi

# Run link check with appropriate settings
echo "🔗 Checking links in README.md..."
lychee \
    --no-progress \
    --verbose \
    --accept 200,999 \
    --max-redirects 5 \
    --retry-wait-time 2 \
    --timeout 20 \
    --exclude-path .lycheeignore \
    README.md

if [ $? -eq 0 ]; then
    echo "✅ All links are working!"
else
    echo "❌ Some links are broken. Please review the output above."
    exit 1
fi