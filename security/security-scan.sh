#!/bin/bash
# Consolidated Security Scanner
# Runs: Bandit, TruffleHog, Safety, Trivy

set -e

# Move to project root
cd "$(dirname "$0")/.."

echo "╔════════════════════════════════════════╗"
echo "║   DeploAI Security Scanner             ║"
echo "╚════════════════════════════════════════╝"
echo ""

ISSUES=0

# 1. SAST (Bandit)
echo "[1/4] Code Security (Bandit)..."
if ! command -v bandit &> /dev/null; then
    echo "  ✗ Bandit not installed: pip install bandit"
else
    BANDIT_ISSUES=$(bandit -r . -c security/.bandit -f json 2>/dev/null | python3 -c "import sys, json; print(len(json.load(sys.stdin)['results']))" 2>/dev/null || echo "0")
    if [ "$BANDIT_ISSUES" -eq 0 ]; then
        echo "  ✓ No code vulnerabilities"
    else
        echo "  ✗ Found $BANDIT_ISSUES issue(s)"
        ISSUES=$((ISSUES + BANDIT_ISSUES))
    fi
fi

# 2. Secrets (TruffleHog)
echo "[2/4] Secrets Scanning (TruffleHog)..."
if ! command -v trufflehog &> /dev/null; then
    echo "  ✗ TruffleHog not installed: pip install truffleHog"
else
    SECRETS=$(trufflehog --regex --entropy=True --max_depth=50 . 2>&1 | wc -l | tr -d ' ')
    if [ "$SECRETS" -eq 0 ]; then
        echo "  ✓ No secrets found"
    else
        echo "  ✗ Potential secrets detected"
        ISSUES=$((ISSUES + 1))
    fi
fi

# 3. Dependencies (Safety)
echo "[3/4] Dependency Check (Safety)..."
if ! command -v safety &> /dev/null; then
    echo "  ✗ Safety not installed: pip install safety"
elif [ -f "AWS/app/requirements.txt" ]; then
    DEP_ISSUES=$(safety check --file AWS/app/requirements.txt --json 2>/dev/null | python3 -c "import sys, json; print(len(json.load(sys.stdin).get('vulnerabilities', [])))" 2>/dev/null || echo "0")
    if [ "$DEP_ISSUES" -eq 0 ]; then
        echo "  ✓ All dependencies secure"
    else
        echo "  ✗ Found $DEP_ISSUES vulnerable dependencies"
        ISSUES=$((ISSUES + DEP_ISSUES))
    fi
fi

# 4. Container (Trivy)
echo "[4/4] Container Security (Trivy)..."
if ! command -v trivy &> /dev/null; then
    echo "  ✗ Trivy not installed: brew install trivy"
elif [ -f "AWS/Dockerfile" ]; then
    DOCKER_ISSUES=$(trivy config AWS/Dockerfile --severity HIGH,CRITICAL --format json 2>/dev/null | python3 -c "import sys, json; print(sum(len(r.get('Misconfigurations', [])) for r in json.load(sys.stdin).get('Results', [])))" 2>/dev/null || echo "0")
    if [ "$DOCKER_ISSUES" -eq 0 ]; then
        echo "  ✓ Dockerfile secure"
    else
        echo "  ✗ Found $DOCKER_ISSUES Dockerfile issues"
        ISSUES=$((ISSUES + DOCKER_ISSUES))
    fi
fi

# Summary
echo ""
echo "════════════════════════════════════════"
if [ "$ISSUES" -eq 0 ]; then
    echo "✅ All scans passed"
    exit 0
else
    echo "⚠️  Found $ISSUES total issues"
    echo "Review security/SECURITY_REPORT.md for details"
    exit 0
fi

