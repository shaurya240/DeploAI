#!/bin/bash
# Install Git hooks for security scanning
# Run this script after cloning the repository

set -e

cd "$(dirname "$0")/.."

echo "╔════════════════════════════════════════╗"
echo "║   Installing DeploAI Git Hooks         ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Check if .git directory exists
if [ ! -d ".git" ]; then
    echo "❌ Error: .git directory not found"
    echo "   Make sure you're running this from the repository root"
    exit 1
fi

# Create hooks directory if it doesn't exist
mkdir -p .git/hooks

# Install pre-push hook
echo "📦 Installing pre-push hook..."
cat > .git/hooks/pre-push << 'EOF'
#!/bin/bash
# Pre-push hook: Run security scans before pushing
# This hook is called with the following parameters:
# $1 -- Name of the remote to which the push is being done
# $2 -- URL to which the push is being done

echo "🔒 Running security scan before push..."
echo ""

# Run the security scanner
./security/security-scan.sh

SCAN_EXIT=$?

if [ $SCAN_EXIT -ne 0 ]; then
    echo ""
    echo "❌ Security scan failed!"
    echo "Please review and fix security issues before pushing."
    echo "To skip this check (not recommended): git push --no-verify"
    exit 1
fi

echo ""
echo "✅ Security scan passed - proceeding with push"
exit 0
EOF

# Make the hook executable
chmod +x .git/hooks/pre-push

echo "✅ Pre-push hook installed successfully!"
echo ""
echo "ℹ️  The security scan will now run automatically before every push."
echo "   To bypass the hook (not recommended): git push --no-verify"
echo ""

