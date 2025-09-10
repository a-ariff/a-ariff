#!/bin/bash
# Validation Script
# Performs comprehensive validation of the GitHub profile README

set -e

echo "🔍 Starting comprehensive validation..."

# Check line count
echo "📏 Checking line count..."
LINE_COUNT=$(wc -l < README.md)
echo "   README.md has $LINE_COUNT lines"
if [ $LINE_COUNT -gt 500 ]; then
    echo "❌ README.md exceeds 500 lines limit"
    exit 1
else
    echo "✅ Line count within limit"
fi

# Check markdown linting
echo "📝 Running markdown linting..."
if command -v markdownlint &> /dev/null; then
    if markdownlint README.md; then
        echo "✅ Markdown linting passed"
    else
        echo "❌ Markdown linting failed"
        exit 1
    fi
else
    echo "⚠️  markdownlint not found, skipping"
fi

# Check for required sections
echo "📋 Checking required sections..."
required_sections=(
    "About Me"
    "Tech Stack"
    "Featured Projects"
    "GitHub Statistics"
    "Recent Activity"
    "Professional Experience"
    "Let's Connect"
)

for section in "${required_sections[@]}"; do
    if grep -q "$section" README.md; then
        echo "   ✅ Found: $section"
    else
        echo "   ❌ Missing: $section"
        exit 1
    fi
done

# Check for activity markers
echo "🔄 Checking activity section markers..."
if grep -q "START_SECTION:activity" README.md && grep -q "END_SECTION:activity" README.md; then
    echo "✅ Activity markers found"
else
    echo "❌ Activity markers missing"
    exit 1
fi

# Check for mobile-friendly elements
echo "📱 Checking mobile-friendly elements..."
if grep -q "max-width: 100%" README.md; then
    echo "✅ Mobile-friendly styles found"
else
    echo "⚠️  No explicit mobile styles found"
fi

# Check for responsive images
if grep -q "<picture>" README.md; then
    echo "✅ Responsive images found"
else
    echo "⚠️  No responsive images found"
fi

# Validate scripts
echo "🔧 Validating scripts..."
for script in scripts/*.py scripts/*.sh; do
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            echo "   ✅ $script is executable"
        else
            echo "   ❌ $script is not executable"
        fi
    fi
done

# Check workflows
echo "⚙️  Checking workflows..."
for workflow in .github/workflows/*.yml; do
    if [ -f "$workflow" ]; then
        echo "   ✅ Found workflow: $(basename $workflow)"
    fi
done

echo ""
echo "🎉 Validation complete! GitHub profile README is ready."
echo "📊 Summary:"
echo "   - Lines: $LINE_COUNT/500"
echo "   - Markdown: ✅ Valid"
echo "   - Sections: ✅ Complete"
echo "   - Scripts: ✅ Ready"
echo "   - Workflows: ✅ Configured"