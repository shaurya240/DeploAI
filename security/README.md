# Security

This folder contains all security-related files for the DeploAI project.

## Files

- **`SECURITY_REPORT.md`** - Comprehensive security assessment report
- **`security-scan.sh`** - Automated security scanner (Bandit, TruffleHog, Safety, Trivy)
- **`.bandit`** - Bandit configuration file

## Quick Start

Run the security scanner from the project root:

```bash
./security/security-scan.sh
```

Read the results:

```bash
cat security/SECURITY_REPORT.md
```

## Security Tools Used

1. **Bandit** - SAST (Static Application Security Testing)
2. **TruffleHog** - Secrets detection in git history
3. **Safety** - Python dependency vulnerability scanning
4. **Trivy** - Container and infrastructure security

## Installation

```bash
pip install bandit truffleHog safety
brew install trivy  # macOS
```

## CI/CD Integration

Security scanning is integrated in `.github/workflows/security-pipeline.yml` and runs automatically on:
- Every push to main/develop
- All pull requests
- Daily scheduled scans

