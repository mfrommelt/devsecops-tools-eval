#!/bin/bash
# sync-scan-results.sh - Map security scan results to dashboard format (FIXED)

set -e

echo "🔄 Syncing Security Scan Results for Dashboard"
echo "=============================================="

SECURITY_REPORTS_DIR="security-reports"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Safe arithmetic function
safe_divide() {
    local numerator=$1
    local denominator=$2
    if [ "$denominator" -eq 0 ]; then
        echo "0"
    else
        echo $(( (numerator * 100) / denominator ))
    fi
}

# Check what scan results actually exist
check_existing_results() {
    log "Checking existing scan results..."
    
    echo "📁 Scanning security-reports directory:"
    for dir in "$SECURITY_REPORTS_DIR"/*; do
        if [ -d "$dir" ]; then
            dir_name=$(basename "$dir")
            file_count=$(find "$dir" -type f | wc -l)
            echo "  📂 $dir_name: $file_count files"
            
            # List actual files
            if [ $file_count -gt 0 ]; then
                find "$dir" -name "*.json" -o -name "*.txt" -o -name "*.sarif" | head -5 | sed 's/^/    /'
                if [ $file_count -gt 5 ]; then
                    echo "    ... and $((file_count - 5)) more files"
                fi
            fi
        fi
    done
}

# Combine Semgrep results into a single comprehensive scan
sync_semgrep_results() {
    log "Syncing Semgrep results..."
    
    local semgrep_dir="$SECURITY_REPORTS_DIR/semgrep"
    local target_file="$semgrep_dir/comprehensive-scan.json"
    
    if [ -d "$semgrep_dir" ]; then
        # Check for different Semgrep result files
        local files_found=()
        
        for file in "$semgrep_dir"/*.json; do
            if [ -f "$file" ] && [ -s "$file" ]; then
                files_found+=("$file")
            fi
        done
        
        if [ ${#files_found[@]} -gt 0 ]; then
            log "Found ${#files_found[@]} Semgrep result files"
            
            # Combine all Semgrep results
            echo '{"results": []}' > "$target_file.tmp"
            
            # Use jq to combine all results arrays
            if command -v jq >/dev/null 2>&1; then
                jq -s 'map(select(.results) | .results) | add | {results: .}' "${files_found[@]}" > "$target_file.tmp" 2>/dev/null || {
                    # Fallback: just use the first file
                    cp "${files_found[0]}" "$target_file.tmp"
                }
            else
                # Fallback without jq: use the largest file
                largest_file=$(ls -S "${files_found[@]}" | head -1)
                cp "$largest_file" "$target_file.tmp"
            fi
            
            # Move to final location
            mv "$target_file.tmp" "$target_file"
            
            local result_count=$(jq '.results | length' "$target_file" 2>/dev/null || echo "0")
            success "Semgrep: Combined results ($result_count findings) -> comprehensive-scan.json"
        else
            warning "No valid Semgrep results found"
            echo '{"results": []}' > "$target_file"
        fi
    else
        warning "Semgrep directory not found"
        mkdir -p "$semgrep_dir"
        echo '{"results": []}' > "$target_file"
    fi
}

# Sync TruffleHog results - fix counting method
sync_trufflehog_results() {
    log "Syncing TruffleHog results..."
    
    local trufflehog_dir="$SECURITY_REPORTS_DIR/trufflehog"
    local target_file="$trufflehog_dir/secrets-verified.json"
    
    if [ -d "$trufflehog_dir" ]; then
        # Check for TruffleHog result files
        if [ -f "$target_file" ] && [ -s "$target_file" ]; then
            # Count actual JSON objects, not lines
            local count=0
            if command -v jq >/dev/null 2>&1; then
                # If it's a JSON array
                count=$(jq '. | length' "$target_file" 2>/dev/null || echo "0")
                if [ "$count" -eq 0 ]; then
                    # If it's line-delimited JSON
                    count=$(grep -c '{' "$target_file" 2>/dev/null || echo "0")
                fi
            else
                # Fallback: count lines with opening braces
                count=$(grep -c '{' "$target_file" 2>/dev/null || echo "0")
            fi
            success "TruffleHog: Using existing secrets-verified.json ($count secrets)"
        elif [ -f "$trufflehog_dir/secrets-all.json" ] && [ -s "$trufflehog_dir/secrets-all.json" ]; then
            # Use the all secrets file
            cp "$trufflehog_dir/secrets-all.json" "$target_file"
            local count=$(grep -c '{' "$target_file" 2>/dev/null || echo "0")
            success "TruffleHog: Copied secrets-all.json -> secrets-verified.json ($count secrets)"
        else
            warning "No valid TruffleHog results found"
            echo '[]' > "$target_file"
        fi
    else
        warning "TruffleHog directory not found"
        mkdir -p "$trufflehog_dir"
        echo '[]' > "$target_file"
    fi
}

# Sync Trivy results - better counting
sync_trivy_results() {
    log "Syncing Trivy results..."
    
    local trivy_dir="$SECURITY_REPORTS_DIR/trivy"
    local target_file="$trivy_dir/filesystem.json"
    
    if [ -d "$trivy_dir" ]; then
        # Check for Trivy result files
        if [ -f "$target_file" ] && [ -s "$target_file" ]; then
            local count=0
            if command -v jq >/dev/null 2>&1; then
                count=$(jq '[.Results[]? | select(.Vulnerabilities) | .Vulnerabilities | length] | add // 0' "$target_file" 2>/dev/null || echo "0")
            fi
            success "Trivy: Using existing filesystem.json ($count vulnerabilities)"
        else
            # Check for alternative names
            local found_file=""
            for alt_file in "$trivy_dir"/*.json; do
                if [ -f "$alt_file" ] && [ -s "$alt_file" ]; then
                    found_file="$alt_file"
                    break
                fi
            done
            
            if [ -n "$found_file" ]; then
                cp "$found_file" "$target_file"
                local count=0
                if command -v jq >/dev/null 2>&1; then
                    count=$(jq '[.Results[]? | select(.Vulnerabilities) | .Vulnerabilities | length] | add // 0' "$target_file" 2>/dev/null || echo "0")
                fi
                success "Trivy: Copied $(basename "$found_file") -> filesystem.json ($count vulnerabilities)"
            else
                warning "No valid Trivy results found"
                echo '{"Results": []}' > "$target_file"
            fi
        fi
    else
        warning "Trivy directory not found"
        mkdir -p "$trivy_dir"
        echo '{"Results": []}' > "$target_file"
    fi
}

# Sync Snyk results - check the general directory too
sync_snyk_results() {
    log "Syncing Snyk results..."
    
    local snyk_dir="$SECURITY_REPORTS_DIR/snyk"
    local target_file="$snyk_dir/dependencies.json"
    
    if [ -d "$snyk_dir" ]; then
        # Check for Snyk result files
        if [ -f "$target_file" ] && [ -s "$target_file" ]; then
            local count=0
            if command -v jq >/dev/null 2>&1; then
                count=$(jq '.vulnerabilities | length' "$target_file" 2>/dev/null || echo "0")
                # If that fails, try different structure
                if [ "$count" -eq 0 ]; then
                    count=$(jq 'if type == "array" then length else .vulnerabilities | length end' "$target_file" 2>/dev/null || echo "0")
                fi
            fi
            success "Snyk: Using existing dependencies.json ($count vulnerabilities)"
        else
            # Check in general directory for snyk results
            if [ -f "$SECURITY_REPORTS_DIR/general/snyk-comprehensive.json" ] && [ -s "$SECURITY_REPORTS_DIR/general/snyk-comprehensive.json" ]; then
                cp "$SECURITY_REPORTS_DIR/general/snyk-comprehensive.json" "$target_file"
                local count=0
                if command -v jq >/dev/null 2>&1; then
                    count=$(jq '.vulnerabilities | length' "$target_file" 2>/dev/null || echo "0")
                    if [ "$count" -eq 0 ]; then
                        count=$(jq 'if type == "array" then length else .vulnerabilities | length end' "$target_file" 2>/dev/null || echo "0")
                    fi
                fi
                success "Snyk: Copied from general/snyk-comprehensive.json ($count vulnerabilities)"
            else
                warning "No valid Snyk results found"
                echo '{"vulnerabilities": []}' > "$target_file"
            fi
        fi
    else
        warning "Snyk directory not found"
        mkdir -p "$snyk_dir"
        echo '{"vulnerabilities": []}' > "$target_file"
    fi
}

# Sync ZAP results - combine all 15 files
sync_zap_results() {
    log "Syncing OWASP ZAP results..."
    
    local zap_dir="$SECURITY_REPORTS_DIR/zap"
    local target_file="$zap_dir/baseline-report.json"
    
    if [ -d "$zap_dir" ]; then
        # Combine all ZAP JSON files
        local all_alerts=""
        local total_alerts=0
        local files_processed=0
        
        for zap_file in "$zap_dir"/zap-*.json; do
            if [ -f "$zap_file" ] && [ -s "$zap_file" ]; then
                if command -v jq >/dev/null 2>&1; then
                    local alerts=$(jq '.site[0].alerts // []' "$zap_file" 2>/dev/null || echo "[]")
                    if [ "$alerts" != "[]" ] && [ "$alerts" != "null" ]; then
                        if [ "$files_processed" -eq 0 ]; then
                            all_alerts="$alerts"
                        else
                            all_alerts=$(echo "$all_alerts $alerts" | jq -s 'add' 2>/dev/null || echo "$all_alerts")
                        fi
                        local count=$(echo "$alerts" | jq 'length' 2>/dev/null || echo "0")
                        total_alerts=$((total_alerts + count))
                        files_processed=$((files_processed + 1))
                    fi
                fi
            fi
        done
        
        if [ $total_alerts -gt 0 ]; then
            echo "{\"site\": [{\"alerts\": $all_alerts}]}" > "$target_file"
            success "ZAP: Combined $files_processed files -> baseline-report.json ($total_alerts alerts)"
        else
            echo '{"site": [{"alerts": []}]}' > "$target_file"
            warning "ZAP: No alerts found in $files_processed files"
        fi
    else
        warning "ZAP directory not found"
        mkdir -p "$zap_dir"
        echo '{"site": [{"alerts": []}]}' > "$target_file"
    fi
}

# Generate summary report with safe arithmetic
generate_summary() {
    log "Generating dashboard summary..."
    
    local summary_file="$SECURITY_REPORTS_DIR/dashboard-summary.json"
    
    # Count findings from each tool safely
    local semgrep_count=0
    local trufflehog_count=0
    local trivy_count=0
    local snyk_count=0
    local zap_count=0
    
    # Semgrep count
    if command -v jq >/dev/null 2>&1 && [ -f "$SECURITY_REPORTS_DIR/semgrep/comprehensive-scan.json" ]; then
        semgrep_count=$(jq '.results | length' "$SECURITY_REPORTS_DIR/semgrep/comprehensive-scan.json" 2>/dev/null || echo "0")
    fi
    
    # TruffleHog count (count JSON objects)
    if [ -f "$SECURITY_REPORTS_DIR/trufflehog/secrets-verified.json" ]; then
        if command -v jq >/dev/null 2>&1; then
            trufflehog_count=$(jq '. | length' "$SECURITY_REPORTS_DIR/trufflehog/secrets-verified.json" 2>/dev/null || echo "0")
            if [ "$trufflehog_count" -eq 0 ]; then
                trufflehog_count=$(grep -c '{' "$SECURITY_REPORTS_DIR/trufflehog/secrets-verified.json" 2>/dev/null || echo "0")
            fi
        else
            trufflehog_count=$(grep -c '{' "$SECURITY_REPORTS_DIR/trufflehog/secrets-verified.json" 2>/dev/null || echo "0")
        fi
    fi
    
    # Trivy count
    if command -v jq >/dev/null 2>&1 && [ -f "$SECURITY_REPORTS_DIR/trivy/filesystem.json" ]; then
        trivy_count=$(jq '[.Results[]? | select(.Vulnerabilities) | .Vulnerabilities | length] | add // 0' "$SECURITY_REPORTS_DIR/trivy/filesystem.json" 2>/dev/null || echo "0")
    fi
    
    # Snyk count
    if command -v jq >/dev/null 2>&1 && [ -f "$SECURITY_REPORTS_DIR/snyk/dependencies.json" ]; then
        snyk_count=$(jq '.vulnerabilities | length // 0' "$SECURITY_REPORTS_DIR/snyk/dependencies.json" 2>/dev/null || echo "0")
        if [ "$snyk_count" -eq 0 ]; then
            snyk_count=$(jq 'if type == "array" then length else .vulnerabilities | length // 0 end' "$SECURITY_REPORTS_DIR/snyk/dependencies.json" 2>/dev/null || echo "0")
        fi
    fi
    
    # ZAP count
    if command -v jq >/dev/null 2>&1 && [ -f "$SECURITY_REPORTS_DIR/zap/baseline-report.json" ]; then
        zap_count=$(jq '.site[0].alerts | length // 0' "$SECURITY_REPORTS_DIR/zap/baseline-report.json" 2>/dev/null || echo "0")
    fi
    
    local total_count=$((semgrep_count + trufflehog_count + trivy_count + snyk_count + zap_count))
    
    # Calculate coverage percentages safely
    local semgrep_coverage=$(safe_divide $semgrep_count 40)
    local trufflehog_coverage=$(safe_divide $trufflehog_count 15)
    local trivy_coverage=$(safe_divide $trivy_count 20)
    local snyk_coverage=$(safe_divide $snyk_count 30)
    local zap_coverage=$(safe_divide $zap_count 15)
    
    # Cap coverage at 100%
    [ $semgrep_coverage -gt 100 ] && semgrep_coverage=100
    [ $trufflehog_coverage -gt 100 ] && trufflehog_coverage=100
    [ $trivy_coverage -gt 100 ] && trivy_coverage=100
    [ $snyk_coverage -gt 100 ] && snyk_coverage=100
    [ $zap_coverage -gt 100 ] && zap_coverage=100
    
    # Create summary JSON
    cat > "$summary_file" << EOF
{
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "total_findings": $total_count,
    "tools": {
        "semgrep": {
            "findings": $semgrep_count,
            "expected": 40,
            "coverage": $semgrep_coverage
        },
        "trufflehog": {
            "findings": $trufflehog_count,
            "expected": 15,
            "coverage": $trufflehog_coverage
        },
        "trivy": {
            "findings": $trivy_count,
            "expected": 20,
            "coverage": $trivy_coverage
        },
        "snyk": {
            "findings": $snyk_count,
            "expected": 30,
            "coverage": $snyk_coverage
        },
        "zap": {
            "findings": $zap_count,
            "expected": 15,
            "coverage": $zap_coverage
        }
    }
}
EOF
    
    success "Summary: $total_count total findings across all tools"
    
    echo ""
    echo "📊 Tool Results Summary:"
    echo "  🔍 Semgrep: $semgrep_count findings (expected 40+) - ${semgrep_coverage}% coverage"
    echo "  🔐 TruffleHog: $trufflehog_count secrets (expected 15+) - ${trufflehog_coverage}% coverage"
    echo "  🔍 Trivy: $trivy_count vulnerabilities (expected 20+) - ${trivy_coverage}% coverage"
    echo "  📦 Snyk: $snyk_count vulnerabilities (expected 30+) - ${snyk_coverage}% coverage"
    echo "  🕷️ ZAP: $zap_count alerts (expected 15+) - ${zap_coverage}% coverage"
    echo "  📊 Total: $total_count findings"
    
    # Show status for each tool
    echo ""
    echo "📈 Coverage Status:"
    [ $semgrep_coverage -ge 90 ] && echo "  🔍 Semgrep: ✅ EXCELLENT" || [ $semgrep_coverage -ge 70 ] && echo "  🔍 Semgrep: 🟢 GOOD" || echo "  🔍 Semgrep: ⚠️ PARTIAL"
    [ $trufflehog_coverage -ge 90 ] && echo "  🔐 TruffleHog: ✅ EXCELLENT" || [ $trufflehog_coverage -ge 70 ] && echo "  🔐 TruffleHog: 🟢 GOOD" || echo "  🔐 TruffleHog: ⚠️ PARTIAL"
    [ $trivy_coverage -ge 90 ] && echo "  🔍 Trivy: ✅ EXCELLENT" || [ $trivy_coverage -ge 70 ] && echo "  🔍 Trivy: 🟢 GOOD" || echo "  🔍 Trivy: ⚠️ PARTIAL"
    [ $snyk_coverage -ge 90 ] && echo "  📦 Snyk: ✅ EXCELLENT" || [ $snyk_coverage -ge 70 ] && echo "  📦 Snyk: 🟢 GOOD" || echo "  📦 Snyk: ⚠️ PARTIAL"
    [ $zap_coverage -ge 90 ] && echo "  🕷️ ZAP: ✅ EXCELLENT" || [ $zap_coverage -ge 70 ] && echo "  🕷️ ZAP: 🟢 GOOD" || echo "  🕷️ ZAP: ⚠️ PARTIAL"
}

# Main execution
main() {
    echo ""
    log "Starting security scan results synchronization..."
    echo ""
    
    # Check what exists first
    check_existing_results
    echo ""
    
    # Sync all tool results to dashboard format
    sync_semgrep_results
    sync_trufflehog_results
    sync_trivy_results
    sync_snyk_results
    sync_zap_results
    
    echo ""
    generate_summary
    
    echo ""
    success "Security scan results synchronized for dashboard!"
    echo ""
    echo "🎯 Next Steps:"
    echo "  1. Dashboard should now show results: http://localhost:9000"
    if [ -n "${CODESPACE_NAME:-}" ] && [ -n "${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-}" ]; then
        echo "  2. Codespaces URL: https://${CODESPACE_NAME}-9000.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}/"
    fi
    echo "  3. If still no data, wait 30 seconds for auto-refresh"
    echo "  4. Or manually refresh the dashboard"
    echo ""
    echo "🔧 Troubleshooting:"
    echo "  - Check dashboard container: docker logs csb-security-dashboard"
    echo "  - Restart dashboard: ./start-dashboard.sh"
    echo "  - Re-run this sync: $0"
}

# Execute main function
main "$@"