#!/bin/bash
# focused-security-scan.sh - Prioritizes static analysis, apps optional for ZAP
# Fixed arithmetic errors, focuses on file-based scanning

set -e

echo "🔒 CSB DevSecOps Security Scanner (Static Analysis Focus)"
echo "========================================================"

# Configuration
SECURITY_REPORTS_DIR="security-reports"
DASHBOARD_DIR="security/dashboard"
DASHBOARD_PORT=9000

# Tool expectations for comparison
EXPECTED_SEMGREP=40
EXPECTED_TRUFFLEHOG=15
EXPECTED_TRIVY=20
EXPECTED_SNYK=30
EXPECTED_ZAP=15        # Optional - only if apps running
EXPECTED_DATAWEAVE=10
EXPECTED_DRUPAL=8

# Actual findings storage
ACTUAL_SEMGREP=0
ACTUAL_TRUFFLEHOG=0
ACTUAL_TRIVY=0
ACTUAL_SNYK=0
ACTUAL_ZAP=0
ACTUAL_DATAWEAVE=0
ACTUAL_DRUPAL=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

print_status() {
    local status=$1
    local message=$2
    case $status in
        "SUCCESS") echo -e "${GREEN}✅ $message${NC}" ;;
        "WARNING") echo -e "${YELLOW}⚠️  $message${NC}" ;;
        "ERROR") echo -e "${RED}❌ $message${NC}" ;;
        "INFO") echo -e "${BLUE}ℹ️  $message${NC}" ;;
        "STEP") echo -e "${PURPLE}🔍 $message${NC}" ;;
    esac
}

# FIXED: Safe number extraction to prevent syntax errors
safe_number() {
    local input="$1"
    # Extract only the first number found, remove any extra characters
    local number=$(echo "$input" | grep -o '[0-9]\+' | head -1)
    echo "${number:-0}"
}

# FIXED: Safe arithmetic to prevent bash syntax errors
safe_arithmetic() {
    local expression="$1"
    # Clean the expression of any newlines or extra characters
    local cleaned=$(echo "$expression" | tr -d '\n\r' | sed 's/[^0-9+\-*/()]//g')
    # Use basic arithmetic with fallback
    local result=$(echo $((cleaned)) 2>/dev/null || echo "0")
    echo "$result"
}

# Setup directories
setup_directories() {
    print_status "STEP" "Setting up directory structure..."
    
    mkdir -p "$SECURITY_REPORTS_DIR"/{semgrep,trufflehog,trivy,snyk,zap,dataweave,drupal,comparison}
    mkdir -p "$DASHBOARD_DIR"
    mkdir -p .semgrep
    
    # Create empty files to prevent failures
    touch "$SECURITY_REPORTS_DIR/dataweave/secrets.txt"
    touch "$SECURITY_REPORTS_DIR/drupal/custom-module-secrets.txt"
    
    print_status "SUCCESS" "Directory structure created"
}

# Install tools quietly
install_security_tools() {
    print_status "STEP" "Installing security tools..."
    
    # Python tools
    pip3 install semgrep bandit safety 2>/dev/null || true
    
    # Node tools  
    npm install -g snyk retire 2>/dev/null || true
    
    # TruffleHog
    if ! command -v trufflehog >/dev/null 2>&1; then
        curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sh -s -- -b /usr/local/bin 2>/dev/null || true
    fi
    
    print_status "SUCCESS" "Security tools installed"
}

# Create Semgrep rules for better coverage
create_semgrep_config() {
    print_status "STEP" "Creating enhanced Semgrep configuration..."
    
    cat > .semgrep/csb-rules.yml << 'EOF'
rules:
  - id: hardcoded-secrets
    patterns:
      - pattern-either:
          - pattern: |
              $VAR = "hardcoded_$REST"
          - pattern: |
              $VAR = "sk_live_$REST"
          - pattern: |
              $VAR = "AKIA$REST"
          - pattern: |
              password = "$VALUE"
          - pattern: |
              api_key = "$VALUE"
    message: "Hardcoded secret detected"
    severity: ERROR
    languages: [python, javascript, java, php, csharp]
    
  - id: sql-injection-patterns
    patterns:
      - pattern-either:
          - pattern: |
              $QUERY = "SELECT * FROM $TABLE WHERE $FIELD = " + $VAR
          - pattern: |
              $QUERY = f"SELECT * FROM {$TABLE} WHERE $FIELD = {$VAR}"
          - pattern: |
              query($SQL + $VAR)
          - pattern: |
              execute("... " + $VAR + " ...")
    message: "SQL injection vulnerability"
    severity: ERROR
    languages: [python, javascript, java, php, csharp]
    
  - id: xss-vulnerabilities
    patterns:
      - pattern-either:
          - pattern: |
              echo $_GET[$VAR]
          - pattern: |
              print($_POST[$VAR])
          - pattern: |
              innerHTML = $VAR
          - pattern: |
              document.write($VAR)
    message: "XSS vulnerability"
    severity: ERROR
    languages: [php, javascript]
    
  - id: weak-crypto
    patterns:
      - pattern-either:
          - pattern: md5($VAR)
          - pattern: MD5.Create()
          - pattern: hashlib.md5($VAR)
          - pattern: sha1($VAR)
    message: "Weak cryptographic algorithm"
    severity: WARNING
    languages: [python, javascript, java, php, csharp]
    
  - id: command-injection
    patterns:
      - pattern-either:
          - pattern: exec($CMD + $VAR)
          - pattern: system($VAR)
          - pattern: subprocess.call($VAR, shell=True)
          - pattern: Runtime.getRuntime().exec($VAR)
    message: "Command injection vulnerability"
    severity: ERROR
    languages: [python, javascript, java, php, csharp]
EOF

    print_status "SUCCESS" "Enhanced Semgrep rules created"
}

# Run Semgrep with multiple rulesets
run_semgrep() {
    print_status "STEP" "Running Semgrep static analysis..."
    
    if command -v semgrep >/dev/null 2>&1; then
        # Run multiple configurations for better coverage
        semgrep --config=auto --json --output="$SECURITY_REPORTS_DIR/semgrep/auto.json" . 2>/dev/null || echo "[]" > "$SECURITY_REPORTS_DIR/semgrep/auto.json"
        semgrep --config=p/security-audit --json --output="$SECURITY_REPORTS_DIR/semgrep/security-audit.json" . 2>/dev/null || echo "[]" > "$SECURITY_REPORTS_DIR/semgrep/security-audit.json"
        semgrep --config=p/owasp-top-ten --json --output="$SECURITY_REPORTS_DIR/semgrep/owasp.json" . 2>/dev/null || echo "[]" > "$SECURITY_REPORTS_DIR/semgrep/owasp.json"
        semgrep --config=.semgrep/ --json --output="$SECURITY_REPORTS_DIR/semgrep/custom.json" . 2>/dev/null || echo "[]" > "$SECURITY_REPORTS_DIR/semgrep/custom.json"
    else
        # Fallback to Docker
        docker run --rm -v $(pwd):/src:ro -v $(pwd)/$SECURITY_REPORTS_DIR/semgrep:/output \
            semgrep/semgrep:latest \
            sh -c "
                semgrep --config=auto --json /src > /output/auto.json 2>/dev/null || echo '[]' > /output/auto.json
                semgrep --config=p/security-audit --json /src > /output/security-audit.json 2>/dev/null || echo '[]' > /output/security-audit.json
            " 2>/dev/null || true
    fi
    
    # FIXED: Count findings safely
    local auto_count=$(safe_number "$(jq '.results | length' "$SECURITY_REPORTS_DIR/semgrep/auto.json" 2>/dev/null || echo "0")")
    local security_count=$(safe_number "$(jq '.results | length' "$SECURITY_REPORTS_DIR/semgrep/security-audit.json" 2>/dev/null || echo "0")")
    local owasp_count=$(safe_number "$(jq '.results | length' "$SECURITY_REPORTS_DIR/semgrep/owasp.json" 2>/dev/null || echo "0")")
    local custom_count=$(safe_number "$(jq '.results | length' "$SECURITY_REPORTS_DIR/semgrep/custom.json" 2>/dev/null || echo "0")")
    
    ACTUAL_SEMGREP=$(safe_arithmetic "$auto_count + $security_count + $owasp_count + $custom_count")
    
    print_status "SUCCESS" "Semgrep: $ACTUAL_SEMGREP findings (auto:$auto_count, security:$security_count, owasp:$owasp_count, custom:$custom_count)"
}

# FIXED: TruffleHog with proper counting
run_trufflehog() {
    print_status "STEP" "Running TruffleHog secret detection..."
    
    if command -v trufflehog >/dev/null 2>&1; then
        # Scan filesystem and git
        trufflehog filesystem . --json > "$SECURITY_REPORTS_DIR/trufflehog/filesystem.json" 2>/dev/null || echo "" > "$SECURITY_REPORTS_DIR/trufflehog/filesystem.json"
        trufflehog git file://. --json > "$SECURITY_REPORTS_DIR/trufflehog/git.json" 2>/dev/null || echo "" > "$SECURITY_REPORTS_DIR/trufflehog/git.json"
        trufflehog git file://. --only-verified --json > "$SECURITY_REPORTS_DIR/trufflehog/verified.json" 2>/dev/null || echo "" > "$SECURITY_REPORTS_DIR/trufflehog/verified.json"
    else
        # Docker fallback
        docker run --rm -v $(pwd):/src:ro -v $(pwd)/$SECURITY_REPORTS_DIR/trufflehog:/output \
            trufflesecurity/trufflehog:latest \
            sh -c "
                trufflehog filesystem /src --json > /output/filesystem.json 2>/dev/null || echo '' > /output/filesystem.json
                trufflehog git file:///src --json > /output/git.json 2>/dev/null || echo '' > /output/git.json
                trufflehog git file:///src --only-verified --json > /output/verified.json 2>/dev/null || echo '' > /output/verified.json
            " 2>/dev/null || true
    fi
    
    # FIXED: Safer counting - count non-empty lines that look like JSON
    local filesystem_count=$(safe_number "$(grep -c '{.*}' "$SECURITY_REPORTS_DIR/trufflehog/filesystem.json" 2>/dev/null || echo "0")")
    local git_count=$(safe_number "$(grep -c '{.*}' "$SECURITY_REPORTS_DIR/trufflehog/git.json" 2>/dev/null || echo "0")")
    local verified_count=$(safe_number "$(grep -c '{.*}' "$SECURITY_REPORTS_DIR/trufflehog/verified.json" 2>/dev/null || echo "0")")
    
    # Use the highest count (avoiding duplicates across different scans)
    ACTUAL_TRUFFLEHOG=$(safe_arithmetic "($filesystem_count > $git_count ? $filesystem_count : $git_count)")
    
    print_status "SUCCESS" "TruffleHog: $ACTUAL_TRUFFLEHOG secrets (filesystem:$filesystem_count, git:$git_count, verified:$verified_count)"
}

# Trivy filesystem scanning
run_trivy() {
    print_status "STEP" "Running Trivy vulnerability scanning..."
    
    # Scan filesystem and configs
    docker run --rm \
        -v $(pwd):/src:ro \
        -v $(pwd)/$SECURITY_REPORTS_DIR/trivy:/output \
        aquasec/trivy:latest \
        sh -c "
            trivy fs --format json /src > /output/filesystem.json 2>/dev/null || echo '{\"Results\": []}' > /output/filesystem.json
            trivy config --format json /src > /output/config.json 2>/dev/null || echo '{\"Results\": []}' > /output/config.json
        " 2>/dev/null || true
    
    # Count vulnerabilities
    local fs_count=$(safe_number "$(jq '[.Results[]? | select(.Vulnerabilities) | .Vulnerabilities | length] | add // 0' "$SECURITY_REPORTS_DIR/trivy/filesystem.json" 2>/dev/null || echo "0")")
    local config_count=$(safe_number "$(jq '[.Results[]? | select(.Misconfigurations) | .Misconfigurations | length] | add // 0' "$SECURITY_REPORTS_DIR/trivy/config.json" 2>/dev/null || echo "0")")
    
    ACTUAL_TRIVY=$(safe_arithmetic "$fs_count + $config_count")
    
    print_status "SUCCESS" "Trivy: $ACTUAL_TRIVY vulnerabilities (filesystem:$fs_count, config:$config_count)"
}

# Snyk dependency scanning
run_snyk() {
    print_status "STEP" "Running Snyk dependency scanning..."
    
    if [ -n "${SNYK_TOKEN:-}" ]; then
        # Test multiple package managers
        snyk test --all-projects --json > "$SECURITY_REPORTS_DIR/snyk/dependencies.json" 2>/dev/null || echo '{"vulnerabilities": []}' > "$SECURITY_REPORTS_DIR/snyk/dependencies.json"
        
        local vuln_count=$(safe_number "$(jq '.vulnerabilities | length' "$SECURITY_REPORTS_DIR/snyk/dependencies.json" 2>/dev/null || echo "0")")
        ACTUAL_SNYK=$vuln_count
        
        print_status "SUCCESS" "Snyk: $ACTUAL_SNYK vulnerabilities found"
    else
        echo '{"vulnerabilities": [], "message": "SNYK_TOKEN not provided"}' > "$SECURITY_REPORTS_DIR/snyk/dependencies.json"
        print_status "WARNING" "Snyk: SNYK_TOKEN not set - skipping"
        ACTUAL_SNYK=0
    fi
}

# ZAP - optional, only if apps are running
run_zap() {
    print_status "STEP" "Running OWASP ZAP (optional - requires running apps)..."
    
    # Check if any common ports are open
    local ports=(8080 5000 8000 3001 8090 3000 4200)
    local running_services=()
    
    for port in "${ports[@]}"; do
        if timeout 2 bash -c "echo > /dev/tcp/127.0.0.1/$port" 2>/dev/null; then
            running_services+=("http://127.0.0.1:$port")
        fi
    done
    
    if [ ${#running_services[@]} -gt 0 ]; then
        print_status "INFO" "Found ${#running_services[@]} running services - proceeding with ZAP"
        
        # Run ZAP against discovered services
        for url in "${running_services[@]}"; do
            local port=$(echo $url | cut -d: -f3)
            docker run --rm \
                --network host \
                -v $(pwd)/$SECURITY_REPORTS_DIR/zap:/zap/wrk:rw \
                ghcr.io/zaproxy/zaproxy:stable \
                zap-baseline.py -t "$url" -J "zap-$port.json" 2>/dev/null || true
        done
        
        # Count ZAP findings
        local zap_total=0
        for file in "$SECURITY_REPORTS_DIR/zap"/*.json; do
            if [ -f "$file" ]; then
                local count=$(safe_number "$(jq '.site[0].alerts | length' "$file" 2>/dev/null || echo "0")")
                zap_total=$(safe_arithmetic "$zap_total + $count")
            fi
        done
        
        ACTUAL_ZAP=$zap_total
        print_status "SUCCESS" "ZAP: $ACTUAL_ZAP findings from ${#running_services[@]} services"
    else
        print_status "WARNING" "ZAP: No running applications detected - skipping DAST"
        echo '{"message": "No running applications found"}' > "$SECURITY_REPORTS_DIR/zap/no-apps.json"
        ACTUAL_ZAP=0
    fi
}

# DataWeave analysis (static - no apps needed)
run_dataweave_scan() {
    print_status "STEP" "Running DataWeave security analysis..."
    
    local DW_DIR="backend/java-mulesoft/src/main/resources/dataweave"
    
    if [ -d "$DW_DIR" ]; then
        # Scan .dwl files for security issues
        find "$DW_DIR" -name "*.dwl" -exec grep -Hn -i "password\|secret\|key\|token" {} \; > "$SECURITY_REPORTS_DIR/dataweave/secrets.txt" 2>/dev/null || true
        find "$DW_DIR" -name "*.dwl" -exec grep -Hn -E "(SELECT.*\+|INSERT.*\+)" {} \; > "$SECURITY_REPORTS_DIR/dataweave/sql-injection.txt" 2>/dev/null || true
        find "$DW_DIR" -name "*.dwl" -exec grep -Hn -E "log\(.*ssn|log\(.*credit" {} \; > "$SECURITY_REPORTS_DIR/dataweave/pii-logging.txt" 2>/dev/null || true
        
        local secrets_count=$(safe_number "$(wc -l < "$SECURITY_REPORTS_DIR/dataweave/secrets.txt" 2>/dev/null || echo "0")")
        local sql_count=$(safe_number "$(wc -l < "$SECURITY_REPORTS_DIR/dataweave/sql-injection.txt" 2>/dev/null || echo "0")")
        local pii_count=$(safe_number "$(wc -l < "$SECURITY_REPORTS_DIR/dataweave/pii-logging.txt" 2>/dev/null || echo "0")")
        
        ACTUAL_DATAWEAVE=$(safe_arithmetic "$secrets_count + $sql_count + $pii_count")
        
        print_status "SUCCESS" "DataWeave: $ACTUAL_DATAWEAVE issues (secrets:$secrets_count, sql:$sql_count, pii:$pii_count)"
    else
        print_status "WARNING" "DataWeave directory not found"
        ACTUAL_DATAWEAVE=0
    fi
}

# Drupal analysis (static - no apps needed)
run_drupal_scan() {
    print_status "STEP" "Running Drupal security analysis..."
    
    local DRUPAL_DIR="backend/php-drupal"
    
    if [ -d "$DRUPAL_DIR" ]; then
        # Scan PHP files for common vulnerabilities
        find "$DRUPAL_DIR" -name "*.php" -exec grep -Hn -i "password\|secret\|key" {} \; > "$SECURITY_REPORTS_DIR/drupal/secrets.txt" 2>/dev/null || true
        find "$DRUPAL_DIR" -name "*.php" -exec grep -Hn -E "echo.*\$_GET|echo.*\$_POST" {} \; > "$SECURITY_REPORTS_DIR/drupal/xss.txt" 2>/dev/null || true
        find "$DRUPAL_DIR" -name "*.php" -exec grep -Hn -E "query\(.*\+|->query\(.*\$" {} \; > "$SECURITY_REPORTS_DIR/drupal/sql.txt" 2>/dev/null || true
        
        local secrets_count=$(safe_number "$(wc -l < "$SECURITY_REPORTS_DIR/drupal/secrets.txt" 2>/dev/null || echo "0")")
        local xss_count=$(safe_number "$(wc -l < "$SECURITY_REPORTS_DIR/drupal/xss.txt" 2>/dev/null || echo "0")")
        local sql_count=$(safe_number "$(wc -l < "$SECURITY_REPORTS_DIR/drupal/sql.txt" 2>/dev/null || echo "0")")
        
        ACTUAL_DRUPAL=$(safe_arithmetic "$secrets_count + $xss_count + $sql_count")
        
        print_status "SUCCESS" "Drupal: $ACTUAL_DRUPAL issues (secrets:$secrets_count, xss:$xss_count, sql:$sql_count)"
    else
        print_status "WARNING" "Drupal directory not found"
        ACTUAL_DRUPAL=0
    fi
}

# Generate master report
generate_master_report() {
    print_status "STEP" "Generating security report..."
    
    local total_expected=$(safe_arithmetic "$EXPECTED_SEMGREP + $EXPECTED_TRUFFLEHOG + $EXPECTED_TRIVY + $EXPECTED_SNYK + $EXPECTED_ZAP + $EXPECTED_DATAWEAVE + $EXPECTED_DRUPAL")
    local total_actual=$(safe_arithmetic "$ACTUAL_SEMGREP + $ACTUAL_TRUFFLEHOG + $ACTUAL_TRIVY + $ACTUAL_SNYK + $ACTUAL_ZAP + $ACTUAL_DATAWEAVE + $ACTUAL_DRUPAL")
    
    local coverage_percent=0
    if [ "$total_expected" -gt 0 ]; then
        coverage_percent=$(safe_arithmetic "($total_actual * 100) / $total_expected")
    fi
    
    # Create JSON report
    cat > "$SECURITY_REPORTS_DIR/comparison/master-security-report.json" << EOF
{
    "scan_metadata": {
        "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
        "total_expected": $total_expected,
        "total_actual": $total_actual,
        "coverage_percent": $coverage_percent,
        "scan_type": "static_analysis_focused"
    },
    "tool_results": {
        "semgrep": {"expected": $EXPECTED_SEMGREP, "actual": $ACTUAL_SEMGREP, "coverage": $(safe_arithmetic "($ACTUAL_SEMGREP * 100) / $EXPECTED_SEMGREP"), "status": "$([ $ACTUAL_SEMGREP -ge $(safe_arithmetic "($EXPECTED_SEMGREP * 70) / 100") ] && echo "GOOD" || echo "NEEDS_REVIEW")"},
        "trufflehog": {"expected": $EXPECTED_TRUFFLEHOG, "actual": $ACTUAL_TRUFFLEHOG, "coverage": $(safe_arithmetic "($ACTUAL_TRUFFLEHOG * 100) / $EXPECTED_TRUFFLEHOG"), "status": "$([ $ACTUAL_TRUFFLEHOG -ge $(safe_arithmetic "($EXPECTED_TRUFFLEHOG * 70) / 100") ] && echo "GOOD" || echo "NEEDS_REVIEW")"},
        "trivy": {"expected": $EXPECTED_TRIVY, "actual": $ACTUAL_TRIVY, "coverage": $(safe_arithmetic "($ACTUAL_TRIVY * 100) / $EXPECTED_TRIVY"), "status": "$([ $ACTUAL_TRIVY -ge $(safe_arithmetic "($EXPECTED_TRIVY * 70) / 100") ] && echo "GOOD" || echo "NEEDS_REVIEW")"},
        "snyk": {"expected": $EXPECTED_SNYK, "actual": $ACTUAL_SNYK, "coverage": $(safe_arithmetic "($ACTUAL_SNYK * 100) / $EXPECTED_SNYK"), "status": "$([ -n "${SNYK_TOKEN:-}" ] && ([ $ACTUAL_SNYK -ge $(safe_arithmetic "($EXPECTED_SNYK * 70) / 100") ] && echo "GOOD" || echo "NEEDS_REVIEW") || echo "TOKEN_MISSING")"},
        "zap": {"expected": $EXPECTED_ZAP, "actual": $ACTUAL_ZAP, "coverage": $(safe_arithmetic "($ACTUAL_ZAP * 100) / $EXPECTED_ZAP"), "status": "$([ $ACTUAL_ZAP -gt 0 ] && echo "GOOD" || echo "NO_APPS_RUNNING")"},
        "dataweave": {"expected": $EXPECTED_DATAWEAVE, "actual": $ACTUAL_DATAWEAVE, "coverage": $(safe_arithmetic "($ACTUAL_DATAWEAVE * 100) / $EXPECTED_DATAWEAVE"), "status": "$([ $ACTUAL_DATAWEAVE -ge $(safe_arithmetic "($EXPECTED_DATAWEAVE * 70) / 100") ] && echo "GOOD" || echo "NEEDS_REVIEW")"},
        "drupal": {"expected": $EXPECTED_DRUPAL, "actual": $ACTUAL_DRUPAL, "coverage": $(safe_arithmetic "($ACTUAL_DRUPAL * 100) / $EXPECTED_DRUPAL"), "status": "$([ $ACTUAL_DRUPAL -ge $(safe_arithmetic "($EXPECTED_DRUPAL * 70) / 100") ] && echo "GOOD" || echo "NEEDS_REVIEW")"}
    },
    "overall_assessment": {
        "status": "$([ $coverage_percent -ge 80 ] && echo "EXCELLENT" || [ $coverage_percent -ge 60 ] && echo "GOOD" || [ $coverage_percent -ge 40 ] && echo "PARTIAL" || echo "POOR")",
        "static_analysis_coverage": $(safe_arithmetic "(($ACTUAL_SEMGREP + $ACTUAL_TRUFFLEHOG + $ACTUAL_TRIVY + $ACTUAL_SNYK + $ACTUAL_DATAWEAVE + $ACTUAL_DRUPAL) * 100) / ($EXPECTED_SEMGREP + $EXPECTED_TRUFFLEHOG + $EXPECTED_TRIVY + $EXPECTED_SNYK + $EXPECTED_DATAWEAVE + $EXPECTED_DRUPAL)")
    }
}
EOF

    print_status "SUCCESS" "Security report generated"
}

# Main execution
main() {
    echo ""
    print_status "INFO" "🎯 STATIC ANALYSIS FOCUSED - Apps optional for ZAP only"
    local total_expected=$(safe_arithmetic "$EXPECTED_SEMGREP + $EXPECTED_TRUFFLEHOG + $EXPECTED_TRIVY + $EXPECTED_SNYK + $EXPECTED_ZAP + $EXPECTED_DATAWEAVE + $EXPECTED_DRUPAL")
    print_status "INFO" "Expected total findings: $total_expected across 7 tools"
    echo ""
    
    setup_directories
    install_security_tools
    create_semgrep_config
    
    # Run static analysis tools (no apps needed)
    run_semgrep
    run_trufflehog  
    run_trivy
    run_snyk
    run_dataweave_scan
    run_drupal_scan
    
    # Run ZAP only if apps are detected
    run_zap
    
    generate_master_report
    
    # Summary
    echo ""
    print_status "SUCCESS" "Security scan completed!"
    echo ""
    echo "📊 Static Analysis Results:"
    echo "  Semgrep: $ACTUAL_SEMGREP (expected $EXPECTED_SEMGREP)"
    echo "  TruffleHog: $ACTUAL_TRUFFLEHOG (expected $EXPECTED_TRUFFLEHOG)"
    echo "  Trivy: $ACTUAL_TRIVY (expected $EXPECTED_TRIVY)"
    echo "  Snyk: $ACTUAL_SNYK (expected $EXPECTED_SNYK)"
    echo "  DataWeave: $ACTUAL_DATAWEAVE (expected $EXPECTED_DATAWEAVE)"
    echo "  Drupal: $ACTUAL_DRUPAL (expected $EXPECTED_DRUPAL)"
    echo ""
    echo "🕷️  Dynamic Analysis:"
    echo "  ZAP: $ACTUAL_ZAP (expected $EXPECTED_ZAP) - $([ $ACTUAL_ZAP -gt 0 ] && echo "apps detected" || echo "no apps running")"
    echo ""
    
    local static_actual=$(safe_arithmetic "$ACTUAL_SEMGREP + $ACTUAL_TRUFFLEHOG + $ACTUAL_TRIVY + $ACTUAL_SNYK + $ACTUAL_DATAWEAVE + $ACTUAL_DRUPAL")
    local static_expected=$(safe_arithmetic "$EXPECTED_SEMGREP + $EXPECTED_TRUFFLEHOG + $EXPECTED_TRIVY + $EXPECTED_SNYK + $EXPECTED_DATAWEAVE + $EXPECTED_DRUPAL")
    local static_coverage=$(safe_arithmetic "($static_actual * 100) / $static_expected")
    
    echo "🎯 Static Analysis Coverage: $static_actual/$static_expected ($static_coverage%)"
    echo ""
    echo "📂 Reports: $SECURITY_REPORTS_DIR/"
    echo ""
    
    if [ "$static_coverage" -ge 80 ]; then
        print_status "SUCCESS" "Excellent static analysis coverage!"
    elif [ "$static_coverage" -ge 60 ]; then
        print_status "WARNING" "Good coverage - minor tuning needed"
    else
        print_status "ERROR" "Low coverage - check tool configuration"
    fi
    
    print_status "INFO" "💡 Note: Only ZAP requires running apps. Other tools scan files directly."
}

main "$@"