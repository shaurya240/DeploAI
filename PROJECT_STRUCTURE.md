# Project Structure

## Clean Directory Layout

```
DeploAI/
├── README.md                    # Project overview
├── PROJECT_STRUCTURE.md        # This file
├── .gitignore                  # Prevents clutter
│
├── security/                   # 🔒 All security files
│   ├── SECURITY_REPORT.md      # Consolidated security findings
│   ├── security-scan.sh        # Single security scanner script
│   └── .bandit                 # Bandit config (minimal)
│
├── AWS/
│   ├── Dockerfile              # Container configuration
│   ├── app/
│   │   ├── weather_ai_agent.py # Main application
│   │   └── requirements.txt    # Python dependencies
│   └── Static S3 Website/
│       └── index.html          # Frontend
│
└── Code/
    ├── agent_01.py             # Local examples
    ├── agent_02.py
    └── agent_poc.py
```

## Key Files

### Security (security/ folder)
- **`SECURITY_REPORT.md`** - All security findings in one place
- **`security-scan.sh`** - Runs all security tools
- **`.bandit`** - SAST configuration

### Application
- **`AWS/app/weather_ai_agent.py`** - Main FastAPI application
- **`AWS/Dockerfile`** - Container definition
- **`AWS/app/requirements.txt`** - Dependencies

### Configuration
- **`.gitignore`** - Excludes generated reports (json, html, txt)

## What Was Removed

❌ Redundant report formats (.json, .html, .txt)  
❌ Multiple overlapping documentation files  
❌ Redundant security scanning scripts  
❌ Generated report directories  

## Quick Start

```bash
# Run security scan
./security/security-scan.sh

# Read results
cat security/SECURITY_REPORT.md

# Run application locally
cd AWS/app
pip install -r requirements.txt
uvicorn weather_ai_agent:app --reload
```

## Security Tools

All tools output to stdout - no file clutter:
- **Bandit** - SAST (code analysis)
- **TruffleHog** - Secrets scanning
- **Safety** - Dependency CVEs
- **Trivy** - Container security

Reports are kept in one consolidated .md file only.

