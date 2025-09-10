#!/bin/bash
# Markdown Linter Script
# Lints README.md and fixes common issues

set -e

echo "📝 Starting markdown lint for README.md..."

# Check if markdownlint-cli is available
if ! command -v markdownlint &> /dev/null; then
    echo "❌ markdownlint not found. Installing..."
    npm install -g markdownlint-cli
fi

# Create markdownlint config if it doesn't exist
if [ ! -f .markdownlint.json ]; then
    echo "📄 Creating .markdownlint.json configuration..."
    cat > .markdownlint.json << 'EOF'
{
  "MD013": {
    "line_length": 100,
    "code_blocks": false,
    "tables": false,
    "headings": false
  },
  "MD033": false,
  "MD041": false,
  "MD036": false
}
EOF
fi

# Run markdown linter
echo "🔍 Linting README.md..."
if markdownlint README.md; then
    echo "✅ Markdown linting passed!"
else
    echo "❌ Markdown linting failed. Please review the output above."
    exit 1
fi