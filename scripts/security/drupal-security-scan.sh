#!/bin/bash
# scripts/security/drupal-security-scan.sh

echo "🔍 Drupal Security Analysis Starting..."

DRUPAL_DIR="backend/php-drupal"
SECURITY_REPORTS_DIR="security-reports/drupal"

mkdir -p "$SECURITY_REPORTS_DIR"

echo "📂 Scanning Drupal installation: $DRUPAL_DIR"

# 1. Drupal Core Security Check
echo "🏗️  Checking Drupal core security..."
cd "$DRUPAL_DIR"

if command -v drush &> /dev/null; then
    # Check for security updates
    drush pm:security 2>&1 | tee "$SECURITY_REPORTS_DIR/core-security-updates.txt"
    
    # Check installed modules
    drush pm:list --status=enabled --format=json > "$SECURITY_REPORTS_DIR/enabled-modules.json"
    
    # Check for outdated modules
    drush pm:updatestatus --format=json > "$SECURITY_REPORTS_DIR/update-status.json"
else
    echo "⚠️  Drush not found. Install drush for comprehensive Drupal scanning."
fi

# 2. Custom Module Security Scan
echo "🔍 Scanning custom modules for vulnerabilities..."
find "$DRUPAL_DIR/web/modules/custom" -name "*.module" -o -name "*.php" | xargs grep -Hn -i "password\|secret\|key\|token" > "$SECURITY_REPORTS_DIR/custom-module-secrets.txt"

# 3. SQL Injection Pattern Detection
echo "💉 Scanning for SQL injection vulnerabilities..."
find "$DRUPAL_DIR/web/modules/custom" "$DRUPAL_DIR/web/themes/custom" -name "*.php" -exec grep -Hn -E "(query\(.*\+|->query\(.*\$)" {} \; > "$SECURITY_REPORTS_DIR/sql-injection-patterns.txt"

# 4. XSS Vulnerability Detection
echo "🔓 Scanning for XSS vulnerabilities..."
find "$DRUPAL_DIR/web/modules/custom" "$DRUPAL_DIR/web/themes/custom" -name "*.php" -exec grep -Hn -E "(echo.*\$_GET|echo.*\$_POST|print.*\$_REQUEST)" {} \; > "$SECURITY_REPORTS_DIR/xss-patterns.txt"

# 5. File Upload Vulnerabilities
echo "📁 Scanning for file upload vulnerabilities..."
find "$DRUPAL_DIR/web/modules/custom" -name "*.php" -exec grep -Hn -E "(file_put_contents|move_uploaded_file|fwrite)" {} \; > "$SECURITY_REPORTS_DIR/file-upload-risks.txt"

# 6. PII Data Exposure
echo "👤 Scanning for PII exposure in logs..."
find "$DRUPAL_DIR/web/modules/custom" "$DRUPAL_DIR/web/themes/custom" -name "*.php" -exec grep -Hn -E "(logger.*ssn|logger.*credit|logger.*password)" {} \; > "$SECURITY_REPORTS_DIR/pii-logging.txt"

# 7. Drupal-specific Security Rules with Semgrep
echo "🔍 Running Drupal-specific Semgrep rules..."
if command -v semgrep &> /dev/null; then
    semgrep --config=.semgrep/drupal-rules.yml "$DRUPAL_DIR" --json > "$SECURITY_REPORTS_DIR/semgrep-drupal.json"
    semgrep --config=.semgrep/drupal-rules.yml "$DRUPAL_DIR" --sarif > "$SECURITY_REPORTS_DIR/semgrep-drupal.sarif"
fi

# 8. Generate Drupal Security Report
echo "📊 Generating Drupal security summary..."
cat > "$SECURITY_REPORTS_DIR/drupal-security-summary.md" << EOF
# Drupal Security Analysis Report

**Generated on:** $(date)

## Summary of Findings

### 🏗️ Core Security
- **Security updates available:** $(wc -l < "$SECURITY_REPORTS_DIR/core-security-updates.txt" 2>/dev/null || echo "N/A")
- **Enabled modules:** $(jq '. | length' "$SECURITY_REPORTS_DIR/enabled-modules.json" 2>/dev/null || echo "N/A")

### 🔐 Custom Code Security
- **Hardcoded secrets:** $(wc -l < "$SECURITY_REPORTS_DIR/custom-module-secrets.txt")
- **SQL injection patterns:** $(wc -l < "$SECURITY_REPORTS_DIR/sql-injection-patterns.txt")
- **XSS vulnerabilities:** $(wc -l < "$SECURITY_REPORTS_DIR/xss-patterns.txt")
- **File upload risks:** $(wc -l < "$SECURITY_REPORTS_DIR/file-upload-risks.txt")

### 👤 Compliance Issues
- **PII in logs:** $(wc -l < "$SECURITY_REPORTS_DIR/pii-logging.txt")

## Recommendations

### Immediate Actions Required
1. **Update Drupal core** to latest security release
2. **Remove all hardcoded secrets** from custom modules
3. **Fix SQL# CSB DevSecOps Test Repository - Complete Enhanced Version

This repository serves as a comprehensive testing ground for CSB's DevSecOps pipeline, security tools, and CI/CD processes. It contains sample applications across our entire technology stack with intentional security vulnerabilities to validate our security scanning capabilities, including **MuleSoft DataWeave transformations** and **Drupal security testing**.

⚠️ **WARNING**: This repository contains **intentional security vulnerabilities** for testing purposes. **DO NOT** deploy to production environments.

## 🏗️ Complete Repository Structure