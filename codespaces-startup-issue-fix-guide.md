# 🚨 Codespaces Startup Issue - Quick Fix Guide

## 🔍 What Happened

Your Codespace failed to start properly due to a permission issue with shell scripts. The error was:

```
/bin/sh: 1: .devcontainer/update.sh: Permission denied
updateContentCommand from devcontainer.json failed with exit code 126
```

This caused Codespaces to fall back to a basic Alpine container instead of the full DevSecOps environment.

## 🔧 Immediate Fix (2 minutes)

### Option 1: Quick Terminal Fix

Run this in your Codespace terminal:

```bash
# Download and run the quick fix script
curl -sSL https://raw.githubusercontent.com/csb/devsecops-test/main/codespaces-quick-fix.sh | bash

# Or if the file exists locally:
chmod +x codespaces-quick-fix.sh
./codespaces-quick-fix.sh
```

### Option 2: Manual Fix

```bash
# 1. Fix all script permissions
find . -name "*.sh" -type f -exec chmod +x {} \;
chmod +x .devcontainer/*

# 2. Run the setup manually
bash .devcontainer/setup.sh

# 3. Start the environment
./start-with-dependencies.sh
```

## 🛠️ Complete Recovery Process

If you need a full reset:

### Step 1: Delete and Recreate Codespace
1. Go to https://github.com/codespaces
2. Delete the current codespace
3. Create a new one with the updated devcontainer.json

### Step 2: Verify New Codespace Works
```bash
# Check if tools are installed
semgrep --version
trufflehog --version
docker --version

# Start all services
./start-with-dependencies.sh

# Run security scans
./scripts/security/run-security-scans.sh
```

## 🔄 Updated Configuration

The issue has been fixed in the updated `devcontainer.json`. The key changes:

```json
{
  "postCreateCommand": "chmod +x .devcontainer/setup.sh .devcontainer/update.sh scripts/**/*.sh *.sh && .devcontainer/setup.sh",
  "updateContentCommand": "chmod +x .devcontainer/setup.sh .devcontainer/update.sh scripts/**/*.sh *.sh 2>/dev/null || true && echo 'Updating dependencies...' && bash .devcontainer/update.sh"
}
```

## ✅ How to Verify It's Working

After the fix, you should see:

```bash
# 1. All security tools available
$ semgrep --version
$ trufflehog --version  
$ snyk --version

# 2. Services starting properly
$ ./start-with-dependencies.sh
✅ PostgreSQL is ready!
✅ MySQL is ready!
✅ Spring Boot API is ready!
# ... all services

# 3. Security scans finding issues
$ ./scripts/security/run-security-scans.sh
🔐 TruffleHog: 25 secrets found
🔍 Semgrep: 52 issues found
📦 Snyk: 38 CVEs found
# ... expected ~150 total findings
```

## 🎯 Expected Results

Once working correctly, you should see:

| Tool | Expected Findings | What It Detects |
|------|------------------|-----------------|
| TruffleHog | 20-30 secrets | Hardcoded passwords, API keys |
| Semgrep | 45-65 issues | SQL injection, XSS, command injection |
| Snyk | 30-50 CVEs | Vulnerable dependencies |
| Trivy | 25-40 vulns | Container vulnerabilities |
| OWASP ZAP | 15-25 issues | Web application flaws |

## 🌐 Service Access

In a working Codespace, these URLs should be automatically forwarded:

- **React App**: `https://{codespace}-3000.{domain}/`
- **Spring Boot API**: `https://{codespace}-8080.{domain}/api/health`
- **Security Dashboard**: `https://{codespace}-9000.{domain}/`
- **Django API**: `https://{codespace}-8000.{domain}/`
- **Flask API**: `https://{codespace}-5000.{domain}/`

## 🆘 If Still Having Issues

### Check VS Code Ports Tab
1. Click **"Ports"** tab in VS Code
2. Look for ports 3000, 4200, 8080, 8888, 9000
3. Click the **globe icon** to open services

### Run Diagnostics
```bash
# Comprehensive system check
./comprehensive-diagnostics.sh

# Service-specific testing for Codespaces
./codespaces-specific-service-testing.sh

# Container recovery if needed
./container-recovery.sh
```

### Check Container Status
```bash
# See what's running
docker-compose ps

# Check specific service logs
docker-compose logs spring-boot-api
docker-compose logs django-app
```

## 💡 Prevention

To prevent this issue in the future:

1. **Always** set execute permissions on shell scripts before committing:
   ```bash
   git add *.sh
   git update-index --chmod=+x *.sh
   ```

2. **Test** your devcontainer locally before pushing:
   ```bash
   devcontainer up --workspace-folder .
   ```

3. **Use** the updated devcontainer.json that handles permissions automatically

## 📞 Getting Help

If you're still stuck:

1. **Check** this troubleshooting guide
2. **Run** `./comprehensive-diagnostics.sh` and share the output
3. **Create** a GitHub issue with the full error log
4. **Contact** #devops-support Slack channel

---

**The good news**: This is a common, easily fixable issue! Once resolved, you'll have the full DevSecOps environment with 150+ intentional vulnerabilities ready for testing. 🎯