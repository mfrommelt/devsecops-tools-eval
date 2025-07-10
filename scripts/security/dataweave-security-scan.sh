#!/bin/bash
# scripts/security/dataweave-security-scan.sh

echo "🔍 DataWeave Security Analysis Starting..."

DW_FILES_DIR="backend/java-mulesoft/src/main/resources/dataweave"
SECURITY_REPORTS_DIR="security-reports/dataweave"

mkdir -p "$SECURITY_REPORTS_DIR"

echo "📂 Scanning DataWeave files in: $DW_FILES_DIR"

# 1. Secret Detection in DataWeave files
echo "🔐 Scanning for hardcoded secrets in DataWeave..."
find "$DW_FILES_DIR" -name "*.dwl" -exec grep -Hn -i "password\|secret\|key\|token\|credential" {} \; > "$SECURITY_REPORTS_DIR/secrets.txt"

# 2. PII Detection
echo "👤 Scanning for PII exposure patterns..."
find "$DW_FILES_DIR" -name "*.dwl" -exec grep -Hn -i "ssn\|credit.*card\|social.*security\|cvv\|routing.*number" {} \; > "$SECURITY_REPORTS_DIR/pii-exposure.txt"

# 3. Injection Vulnerability Patterns
echo "💉 Scanning for injection vulnerabilities..."
find "$DW_FILES_DIR" -name "*.dwl" -exec grep -Hn -E "(SELECT.*\+|INSERT.*\+|UPDATE.*\+|DELETE.*\+)" {} \; > "$SECURITY_REPORTS_DIR/sql-injection.txt"

# 4. XSS/Script Injection Patterns
echo "🔓 Scanning for XSS vulnerabilities..."
find "$DW_FILES_DIR" -name "*.dwl" -exec grep -Hn -E "(<script|javascript:|<div.*\+|<.*\+.*>)" {} \; > "$SECURITY_REPORTS_DIR/xss-patterns.txt"

# 5. Unsafe Logging Patterns
echo "📝 Scanning for unsafe logging practices..."
find "$DW_FILES_DIR" -name "*.dwl" -exec grep -Hn -E "(log\(.*ssn|log\(.*credit|log\(.*password|log\(.*key)" {} \; > "$SECURITY_REPORTS_DIR/unsafe-logging.txt"

# 6. Compliance Violations (Banking)
echo "🏦 Scanning for banking compliance violations..."
find "$DW_FILES_DIR" -name "*.dwl" -exec grep -Hn -E "(creditCard|cvv|routingNumber|accountNumber)" {} \; > "$SECURITY_REPORTS_DIR/compliance-violations.txt"

# 7. Custom DataWeave Security Rules with Semgrep
echo "🔍 Running custom DataWeave Semgrep rules..."
if command -v semgrep &> /dev/null; then
    semgrep --config=.semgrep/dataweave-rules.yml "$DW_FILES_DIR" --json > "$SECURITY_REPORTS_DIR/semgrep-dataweave.json"
    semgrep --config=.semgrep/dataweave-rules.yml "$DW_FILES_DIR" --sarif > "$SECURITY_REPORTS_DIR/semgrep-dataweave.sarif"
fi

# 8. Generate DataWeave Security Report
echo "📊 Generating DataWeave security summary..."
cat > "$SECURITY_REPORTS_DIR/dataweave-security-summary.md" << EOF
# DataWeave Security Analysis Report

**Generated on:** $(date)

## Summary of Findings

### 🔐 Secret Detection
- **Hardcoded secrets found:** $(wc -l < "$SECURITY_REPORTS_DIR/secrets.txt")
- **Details:** See secrets.txt

### 👤 PII Exposure
- **PII patterns found:** $(wc -l < "$SECURITY_REPORTS_DIR/pii-exposure.txt")
- **Compliance risk:** HIGH
- **Details:** See pii-exposure.txt

### 💉 Injection Vulnerabilities
- **SQL injection patterns:** $(wc -l < "$SECURITY_REPORTS_DIR/sql-injection.txt")
- **XSS patterns:** $(wc -l < "$SECURITY_REPORTS_DIR/xss-patterns.txt")

### 📝 Logging Violations
- **Unsafe logging patterns:** $(wc -l < "$SECURITY_REPORTS_DIR/unsafe-logging.txt")
- **Compliance impact:** PCI DSS, SOX violations

### 🏦 Banking Compliance
- **Compliance violations:** $(wc -l < "$SECURITY_REPORTS_DIR/compliance-violations.txt")
- **Regulatory risk:** HIGH

## Recommendations

1. **Remove all hardcoded secrets** from DataWeave transformations
2. **Implement proper PII encryption** before logging
3. **Use parameterized queries** instead of string concatenation
4. **Sanitize all HTML output** to prevent XSS
5. **Remove sensitive data** from logs and debug output
6. **Implement proper data masking** for credit card and SSN data

## DataWeave Files Analyzed
$(find "$DW_FILES_DIR" -name "*.dwl" | wc -l) DataWeave files scanned
EOF

echo "✅ DataWeave security analysis complete!"
echo "📋 View summary: cat $SECURITY_REPORTS_DIR/dataweave-security-summary.md"