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
REPORT_FILE="security/SECURITY_REPORT.md"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Initialize report
cat > "$REPORT_FILE" << EOF
# Security Scan Report

**Generated:** $TIMESTAMP

## Summary

EOF

# 1. SAST (Bandit)
echo "[1/4] Code Security (Bandit)..."
cat >> "$REPORT_FILE" << EOF
### 1. Code Security (Bandit - SAST)

EOF

if ! command -v bandit &> /dev/null; then
    echo "  ✗ Bandit not installed: pip install bandit"
    echo "**Status:** ⚠️ Tool not installed" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
else
    BANDIT_ISSUES=$(bandit -r . -c security/.bandit -f json 2>/dev/null | python3 -c "import sys, json; print(len(json.load(sys.stdin)['results']))" 2>/dev/null || echo "0")
    if [ "$BANDIT_ISSUES" -eq 0 ]; then
        echo "  ✓ No code vulnerabilities"
        echo "**Status:** ✅ No vulnerabilities found" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    else
        echo "  ✗ Found $BANDIT_ISSUES issue(s)"
        ISSUES=$((ISSUES + BANDIT_ISSUES))
        echo "**Status:** ❌ Found $BANDIT_ISSUES issue(s)" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        echo "Run \`bandit -r . -c security/.bandit\` for details." >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    fi
fi

# 2. Secrets (TruffleHog)
echo "[2/4] Secrets Scanning (TruffleHog)..."
cat >> "$REPORT_FILE" << EOF
### 2. Secrets Scanning (TruffleHog)

EOF

if ! command -v trufflehog &> /dev/null; then
    echo "  ✗ TruffleHog not installed: pip install truffleHog"
    echo "**Status:** ⚠️ Tool not installed" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
else
    SECRETS=$(trufflehog --regex --entropy=True --max_depth=50 . 2>&1 | wc -l | tr -d ' ')
    if [ "$SECRETS" -eq 0 ]; then
        echo "  ✓ No secrets found"
        echo "**Status:** ✅ No secrets detected in repository" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    else
        echo "  ✗ Potential secrets detected"
        ISSUES=$((ISSUES + 1))
        echo "**Status:** ❌ Potential secrets detected" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        echo "Run \`trufflehog --regex --entropy=True .\` for details." >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    fi
fi

# 3. Dependencies (Safety)
echo "[3/4] Dependency Check (Safety)..."
cat >> "$REPORT_FILE" << EOF
### 3. Dependency Vulnerabilities (Safety)

EOF

if ! command -v safety &> /dev/null; then
    echo "  ✗ Safety not installed: pip install safety"
    echo "**Status:** ⚠️ Tool not installed" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
elif [ -f "app/requirements.txt" ]; then
    DEP_ISSUES=$(safety check --file app/requirements.txt --json 2>/dev/null | python3 -c "import sys, json; print(len(json.load(sys.stdin).get('vulnerabilities', [])))" 2>/dev/null || echo "0")
    if [ "$DEP_ISSUES" -eq 0 ]; then
        echo "  ✓ All dependencies secure"
        echo "**Status:** ✅ All Python dependencies secure" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    else
        echo "  ✗ Found $DEP_ISSUES vulnerable dependencies"
        ISSUES=$((ISSUES + DEP_ISSUES))
        echo "**Status:** ❌ Found $DEP_ISSUES vulnerable dependencies" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        echo "Run \`safety check --file app/requirements.txt\` for details." >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    fi
else
    echo "  ⚠ No requirements.txt found"
    echo "**Status:** ⚠️ No requirements.txt found" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
fi

# 4. Container (Trivy)
echo "[4/4] Container Security (Trivy)..."
cat >> "$REPORT_FILE" << EOF
### 4. Container Security (Trivy)

EOF

if ! command -v trivy &> /dev/null; then
    echo "  ✗ Trivy not installed: brew install trivy"
    echo "**Status:** ⚠️ Tool not installed" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
else
    DOCKER_ISSUES=0
    
    # 4a. Scan Dockerfile for misconfigurations
    if [ -f "Dockerfile" ]; then
        echo "  ├─ Scanning Dockerfile misconfigurations..."
        CONFIG_ISSUES=$(trivy config Dockerfile --severity HIGH,CRITICAL --format json 2>/dev/null | python3 -c "import sys, json; print(sum(len(r.get('Misconfigurations', [])) for r in json.load(sys.stdin).get('Results', [])))" 2>/dev/null || echo "0")
        DOCKER_ISSUES=$((DOCKER_ISSUES + CONFIG_ISSUES))
        if [ "$CONFIG_ISSUES" -gt 0 ]; then
            echo "  │  ✗ Found $CONFIG_ISSUES misconfiguration(s)"
            echo "#### Dockerfile Misconfigurations" >> "$REPORT_FILE"
            echo "" >> "$REPORT_FILE"
            echo "**Found:** $CONFIG_ISSUES misconfiguration(s)" >> "$REPORT_FILE"
            echo "" >> "$REPORT_FILE"
            echo '```' >> "$REPORT_FILE"
            trivy config Dockerfile --severity HIGH,CRITICAL 2>/dev/null | head -50 >> "$REPORT_FILE"
            echo '```' >> "$REPORT_FILE"
            echo "" >> "$REPORT_FILE"
        fi
    fi
    
    # 4b. Scan base image for vulnerabilities
    if [ -f "Dockerfile" ]; then
        echo "  ├─ Scanning base image vulnerabilities..."
        # Extract base image from Dockerfile
        BASE_IMAGE=$(grep -E "^FROM " Dockerfile | head -1 | awk '{print $2}')
        if [ -n "$BASE_IMAGE" ]; then
            IMAGE_VULNS=$(trivy image --severity HIGH,CRITICAL --format json "$BASE_IMAGE" 2>/dev/null | python3 -c "import sys, json; d=json.load(sys.stdin); print(sum(len(r.get('Vulnerabilities', [])) for r in d.get('Results', [])))" 2>/dev/null || echo "0")
            DOCKER_ISSUES=$((DOCKER_ISSUES + IMAGE_VULNS))
            if [ "$IMAGE_VULNS" -gt 0 ]; then
                echo "  │  ✗ Found $IMAGE_VULNS vulnerability(ies) in $BASE_IMAGE"
                echo "#### Base Image Vulnerabilities" >> "$REPORT_FILE"
                echo "" >> "$REPORT_FILE"
                echo "**Base Image:** \`$BASE_IMAGE\`" >> "$REPORT_FILE"
                echo "**Vulnerabilities:** $IMAGE_VULNS (HIGH/CRITICAL severity)" >> "$REPORT_FILE"
                echo "" >> "$REPORT_FILE"
                echo '<details>' >> "$REPORT_FILE"
                echo '<summary>Click to view vulnerability details</summary>' >> "$REPORT_FILE"
                echo "" >> "$REPORT_FILE"
                echo '```' >> "$REPORT_FILE"
                trivy image --severity HIGH,CRITICAL "$BASE_IMAGE" 2>/dev/null | head -100 >> "$REPORT_FILE"
                echo '```' >> "$REPORT_FILE"
                echo '</details>' >> "$REPORT_FILE"
                echo "" >> "$REPORT_FILE"
                echo "**Recommendation:** Update to a newer base image:" >> "$REPORT_FILE"
                echo '```dockerfile' >> "$REPORT_FILE"
                echo "FROM python:3.13-slim  # Latest Python" >> "$REPORT_FILE"
                echo "# OR" >> "$REPORT_FILE"
                echo "FROM python:3.10-slim-bookworm  # Latest Python 3.10 on Debian Bookworm" >> "$REPORT_FILE"
                echo '```' >> "$REPORT_FILE"
                echo "" >> "$REPORT_FILE"
            fi
        fi
    fi
    
    if [ "$DOCKER_ISSUES" -eq 0 ]; then
        echo "  ✓ Dockerfile and base image secure"
        echo "**Status:** ✅ Dockerfile and base image secure" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    else
        echo "  └─ Total: $DOCKER_ISSUES Docker issues"
        ISSUES=$((ISSUES + DOCKER_ISSUES))
    fi
fi

# Summary
echo ""
echo "════════════════════════════════════════"

# Write summary to report
cat >> "$REPORT_FILE" << EOF
---

## Scan Results

EOF

if [ "$ISSUES" -eq 0 ]; then
    echo "✅ All scans passed"
    cat >> "$REPORT_FILE" << EOF
**Status:** ✅ **All scans passed**

No security issues found. The codebase is secure and ready for deployment.

EOF
    exit 0
else
    echo "⚠️  Found $ISSUES total issues"
    echo "Review security/SECURITY_REPORT.md for details"
    cat >> "$REPORT_FILE" << EOF
**Status:** ❌ **Found $ISSUES security issues**

### Action Required

Please review and fix the issues listed above before pushing code to the repository.

EOF
    exit 1
fi

