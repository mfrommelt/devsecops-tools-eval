# CSB DevSecOps Security Validation Guide

## 🎯 Purpose

This guide helps you validate that your security tools are working correctly by comparing expected findings against actual results. Use this to ensure your DevSecOps pipeline is detecting the intentional vulnerabilities in this test environment.

## 📊 Expected vs Actual Findings Dashboard

### 🔍 Overall Security Scan Summary

| Metric | Expected Range | Healthy Status | Validation |
|--------|----------------|----------------|------------|
| **Total Findings** | 140-160 | ✅ Tools working | Count all findings |
| **Critical Issues** | 30-40 | ✅ Detecting major flaws | SQL injection, secrets |
| **High Issues** | 55-65 | ✅ Catching important vulns | XSS, auth bypass |
| **Medium Issues** | 45-55 | ✅ Finding code quality issues | Dependency CVEs |
| **Scan Duration** | <20 minutes | ✅ Performance good | Time all scans |

### 🛠️ Tool-by-Tool Validation

#### 🔐 TruffleHog - Secret Detection

**Expected Results:**
```bash
✅ Expected: 20-30 secrets detected
✅ Key findings should include:
  - Database passwords (hardcoded_*_password_*)
  - API keys (sk_live_*, api_key_*)
  - AWS credentials (AKIA*, wJalrXUtnFEMI*)
  - JWT secrets (hardcoded_jwt_secret_*)
  - Banking credentials (bank_api_*, routing_*)
```

**Validation Commands:**
```bash
# Run TruffleHog scan
docker-compose run --rm trufflehog

# Check results
jq '.Results | length' security-reports/trufflehog/secrets-verified.json

# Validate specific secrets found
grep -i "hardcoded_spring_db_password_789" security-reports/trufflehog/secrets-all.json
grep -i "AKIAIOSFODNN7" security-reports/trufflehog/secrets-all.json
```

**🚨 If TruffleHog finds <15 or >35 secrets:**
- ❌ Too few: Tool may not be scanning all files
- ❌ Too many: May be detecting false positives
- ✅ 20-30 range: Tool working correctly

#### 🔍 Semgrep - Static Analysis

**Expected Results:**
```bash
✅ Expected: 45-60 SAST findings
✅ Key findings should include:
  - SQL injection patterns in Java, Python, PHP
  - XSS vulnerabilities in frontend code
  - Command injection in system calls
  - Hardcoded secrets in configuration
  - Weak cryptography usage (MD5, weak random)
```

**Validation Commands:**
```bash
# Run Semgrep scan
docker-compose run --rm semgrep

# Check results count
jq '.results | length' security-reports/semgrep/comprehensive-scan.json

# Validate specific findings
jq '.results[] | select(.check_id | contains("sql-injection"))' security-reports/semgrep/comprehensive-scan.json
jq '.results[] | select(.check_id | contains("hardcoded"))' security-reports/semgrep/comprehensive-scan.json
```

**🚨 If Semgrep finds <40 or >70 findings:**
- ❌ Too few: Custom rules may not be loading
- ❌ Too many: Rules may be too broad
- ✅ 45-60 range: Tool working correctly

#### 📦 Snyk - Dependency Scanning

**Expected Results:**
```bash
✅ Expected: 30-50 dependency vulnerabilities
✅ Key findings should include:
  - High/Critical CVEs in Node.js packages
  - Vulnerable Java dependencies (Log4j, etc.)
  - Outdated Python packages with known issues
  - .NET packages with security flaws
```

**Validation Commands:**
```bash
# Run Snyk scan (requires SNYK_TOKEN)
docker-compose run --rm snyk

# Check results count
jq '.vulnerabilities | length' security-reports/snyk/dependencies-scan.json

# Check severity distribution
jq '.vulnerabilities | group_by(.severity) | map({severity: .[0].severity, count: length})' security-reports/snyk/dependencies-scan.json
```

**🚨 If Snyk finds <25 or >60 vulnerabilities:**
- ❌ Too few: Token may be missing or dependencies not scanning
- ❌ Too many: May be including dev dependencies
- ✅ 30-50 range: Tool working correctly

#### 🕷️ OWASP ZAP - Dynamic Scanning

**Expected Results:**
```bash
✅ Expected: 15-25 web application vulnerabilities
✅ Key findings should include:
  - Missing security headers
  - Reflected XSS opportunities
  - SQL injection in API endpoints
  - Directory traversal possibilities
  - Weak authentication mechanisms
```

**Validation Commands:**
```bash
# Run ZAP scan
docker-compose run --rm zap

# Check results in HTML reports
ls -la security-reports/zap/

# Count findings in JSON reports
jq '.site[0].alerts | length' security-reports/zap/zap-baseline-report.json
```

**🚨 If ZAP finds <10 or >30 vulnerabilities:**
- ❌ Too few: Services may not be running when scan executes
- ❌ Too many: May be including informational findings
- ✅ 15-25 range: Tool working correctly

#### 🔍 Trivy - Container Scanning

**Expected Results:**
```bash
✅ Expected: 25-40 container/filesystem vulnerabilities
✅ Key findings should include:
  - CVEs in base container images
  - Vulnerable system packages
  - Dependency vulnerabilities
  - Configuration issues
```

**Validation Commands:**
```bash
# Run Trivy scan
docker-compose run --rm trivy

# Check results count
jq '.Results[] | .Vulnerabilities | length' security-reports/trivy/filesystem-scan.json

# Check severity breakdown
jq '.Results[] | .Vulnerabilities | group_by(.Severity) | map({severity: .[0].Severity, count: length})' security-reports/trivy/filesystem-scan.json
```

## 🎯 Application-Specific Testing

### 📊 DataWeave Security Validation

**Expected DataWeave Findings: 15-25**

```bash
# Run DataWeave security scan
./scripts/security/dataweave-security-scan.sh

# Expected findings:
✅ Hardcoded secrets: 8-12 instances
✅ PII exposure: 5-8 instances  
✅ SQL injection patterns: 3-5 instances
✅ Compliance violations: 5-10 instances

# Validation
grep -c "hardcoded.*password" security-reports/dataweave/secrets.txt
grep -c "ssn\|credit.*card" security-reports/dataweave/pii-exposure.txt
```

### 🌐 Drupal Security Validation

**Expected Drupal Findings: 12-20**

```bash
# Run Drupal security scan
./scripts/security/drupal-security-scan.sh

# Expected findings:
✅ SQL injection patterns: 4-6 instances
✅ XSS vulnerabilities: 3-5 instances
✅ Access control issues: 2-4 instances
✅ Hardcoded secrets: 3-5 instances

# Validation
wc -l security-reports/drupal/sql-injection-patterns.txt
wc -l security-reports/drupal/xss-patterns.txt
```

## 🚨 Validation Checklist

### ✅ Pre-Scan Validation

Before running scans, verify:

```bash
# 1. All services are running
docker-compose ps | grep "Up"

# 2. Security tools are available
semgrep --version
snyk --version  
trufflehog --version

# 3. GitHub secrets are configured (for private repos)
echo $SEMGREP_APP_TOKEN | head -c 10
echo $SNYK_TOKEN | head -c 10

# 4. All source code is present
find . -name "*.java" | wc -l  # Should be 3+
find . -name "*.py" | wc -l    # Should be 5+
find . -name "*.dwl" | wc -l   # Should be 5+
```

### ✅ Post-Scan Validation

After running scans, verify:

```bash
# 1. All expected report files exist
ls -la security-reports/*/

# 2. Reports contain expected number of findings
./scripts/security/validate-scan-results.sh

# 3. No scan failures or errors
grep -i "error\|failed" security-reports/*/*.log

# 4. Dashboard is accessible
curl -I http://localhost:9000/ | head -1
```

## 🔧 Creating the Validation Script

Create this script to automate validation:

```bash
#!/bin/bash
# scripts/security/validate-scan-results.sh

echo "🔍 CSB Security Scan Validation"
echo "==============================="

# Count findings by tool
echo "📊 Findings by Tool:"
echo "├── TruffleHog: $(jq '.Results | length' security-reports/trufflehog/secrets-verified.json 2>/dev/null || echo 'N/A')"
echo "├── Semgrep: $(jq '.results | length' security-reports/semgrep/comprehensive-scan.json 2>/dev/null || echo 'N/A')"  
echo "├── Snyk: $(jq '.vulnerabilities | length' security-reports/snyk/dependencies-scan.json 2>/dev/null || echo 'N/A')"
echo "├── Trivy: $(jq '[.Results[]?.Vulnerabilities // []] | add | length' security-reports/trivy/filesystem-scan.json 2>/dev/null || echo 'N/A')"
echo "└── DataWeave: $(wc -l < security-reports/dataweave/secrets.txt 2>/dev/null || echo 'N/A')"

# Validation status
echo ""
echo "✅ Validation Status:"
trufflehog_count=$(jq '.Results | length' security-reports/trufflehog/secrets-verified.json 2>/dev/null || echo 0)
if [ "$trufflehog_count" -ge 20 ] && [ "$trufflehog_count" -le 30 ]; then
    echo "├── TruffleHog: ✅ PASS ($trufflehog_count secrets)"
else
    echo "├── TruffleHog: ❌ FAIL ($trufflehog_count secrets, expected 20-30)"
fi

semgrep_count=$(jq '.results | length' security-reports/semgrep/comprehensive-scan.json 2>/dev/null || echo 0)
if [ "$semgrep_count" -ge 45 ] && [ "$semgrep_count" -le 60 ]; then
    echo "├── Semgrep: ✅ PASS ($semgrep_count findings)"
else
    echo "├── Semgrep: ❌ FAIL ($semgrep_count findings, expected 45-60)"
fi

echo ""
echo "🎯 Overall Assessment:"
total_issues=$((trufflehog_count + semgrep_count))
if [ "$total_issues" -ge 65 ] && [ "$total_issues" -le 90 ]; then
    echo "✅ Security tools are working correctly!"
    echo "   Total findings: $total_issues (expected 65-90)"
else
    echo "❌ Security tools may need attention"
    echo "   Total findings: $total_issues (expected 65-90)"
fi
```

## 🎯 Success Criteria

Your security testing environment is working correctly when:

### ✅ Quantitative Metrics
- **Total Findings**: 140-160 across all tools
- **Critical/High**: 85-105 findings combined  
- **Scan Duration**: <20 minutes for full suite
- **Tool Coverage**: All 8+ tools producing results

### ✅ Qualitative Validation
- **Secret Detection**: Finding hardcoded credentials in multiple languages
- **Injection Flaws**: Detecting SQL injection in Java, Python, PHP
- **XSS Detection**: Finding unsafe HTML rendering
- **Dependency Issues**: Identifying known CVEs in packages
- **Compliance**: Flagging PCI DSS and SOX violations

### ✅ Functional Testing
- **Services Running**: All 9 applications accessible
- **Database Connectivity**: PostgreSQL, MySQL, Oracle connected
- **API Responses**: REST endpoints returning test data
- **Frontend Loading**: React/Angular apps serving pages

## 🚨 Troubleshooting Validation Issues

### ❌ "Too Few Findings Detected"

**Possible Causes & Solutions:**
```bash
# 1. Services not running when scans execute
./start-with-dependencies.sh
sleep 60  # Wait for full startup

# 2. Source code not being scanned
ls -la backend/*/  # Verify code exists
docker-compose run --rm semgrep --dryrun  # Check scan scope

# 3. Tools not configured correctly
.devcontainer/setup.sh  # Reinstall tools
```

### ❌ "Too Many Findings Detected"

**Possible Causes & Solutions:**
```bash
# 1. Scanning unnecessary files
echo "node_modules/" >> .semgrepignore
echo "vendor/" >> .semgrepignore

# 2. Including test/demo data
# Review scan configurations in .semgrep/

# 3. Tool configurations too broad
# Tune tool settings for testing environment
```

### ❌ "Inconsistent Results"

**Possible Causes & Solutions:**
```bash
# 1. Services starting/stopping during scans
# Use proper startup order with health checks

# 2. Network connectivity issues
docker-compose exec spring-boot-api curl http://localhost:8080/health

# 3. Tool version differences
# Pin tool versions in docker-compose.yml
```

## 📞 Getting Help

If your validation results don't match expectations:

1. **🔍 Check this guide**: Compare your results with expected ranges
2. **🛠️ Run diagnostics**: Use `./comprehensive-diagnostics.sh`
3. **📊 Review logs**: Check individual tool logs for errors
4. **💬 Get support**: Contact #devops-support or create GitHub issue

Remember: This environment contains **intentional vulnerabilities** - finding many security issues means your tools are working correctly! 🎯