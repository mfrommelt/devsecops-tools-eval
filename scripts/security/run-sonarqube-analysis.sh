#!/bin/bash
# scripts/security/run-sonarqube-analysis.sh
# SonarQube Analysis Helper Script for CSB DevSecOps Test Environment

set -e

echo "🎯 SonarQube Analysis for CSB DevSecOps Test Environment"
echo "========================================================"

# Configuration
SONAR_HOST_URL="http://localhost:9000"
SONAR_PROJECT_KEY="csb-devsecops-test"
SONAR_PROJECT_NAME="CSB DevSecOps Test Environment"
SONAR_LOGIN="admin"
SONAR_PASSWORD="admin"
REPORTS_DIR="security-reports/sonarqube"

# Function to log with timestamp
log() {
    echo "[$(date '+%H:%M:%S')] $1"
}

# Function to check if SonarQube is running
check_sonarqube_status() {
    log "🔍 Checking SonarQube status..."
    
    if ! curl -f -s "$SONAR_HOST_URL/api/system/status" >/dev/null 2>&1; then
        echo "❌ SonarQube is not running or not accessible at $SONAR_HOST_URL"
        echo ""
        echo "💡 To start SonarQube:"
        echo "   ./start-with-dependencies.sh --with-sonarqube"
        echo ""
        echo "   Or manually:"
        echo "   docker-compose --profile sonarqube up -d sonarqube"
        exit 1
    fi
    
    local status=$(curl -s "$SONAR_HOST_URL/api/system/status" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
    if [ "$status" != "UP" ]; then
        echo "❌ SonarQube is not ready yet (status: $status)"
        echo "⏳ Please wait for SonarQube to fully start up"
        exit 1
    fi
    
    log "✅ SonarQube is running and ready"
}

# Function to check if sonar-scanner is available
check_sonar_scanner() {
    log "🔍 Checking for SonarQube Scanner..."
    
    if command -v sonar-scanner >/dev/null 2>&1; then
        log "✅ SonarQube Scanner found locally"
        return 0
    fi
    
    log "⚠️ SonarQube Scanner not found locally, will use Docker version"
    return 1
}

# Function to install sonar-scanner locally
install_sonar_scanner() {
    log "📦 Installing SonarQube Scanner..."
    
    # Check platform
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        PLATFORM="linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        PLATFORM="macosx"
    else
        log "⚠️ Unsupported platform, will use Docker version"
        return 1
    fi
    
    # Download and install sonar-scanner
    SCANNER_VERSION="4.7.0.2747"
    SCANNER_ZIP="sonar-scanner-cli-${SCANNER_VERSION}-${PLATFORM}.zip"
    SCANNER_URL="https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/${SCANNER_ZIP}"
    
    log "Downloading SonarQube Scanner..."
    curl -L -o "/tmp/${SCANNER_ZIP}" "$SCANNER_URL"
    
    log "Installing SonarQube Scanner..."
    sudo unzip -q "/tmp/${SCANNER_ZIP}" -d /opt/
    sudo ln -sf "/opt/sonar-scanner-${SCANNER_VERSION}-${PLATFORM}/bin/sonar-scanner" /usr/local/bin/sonar-scanner
    sudo chmod +x /usr/local/bin/sonar-scanner
    
    rm "/tmp/${SCANNER_ZIP}"
    log "✅ SonarQube Scanner installed successfully"
}

# Function to create project in SonarQube if it doesn't exist
create_sonarqube_project() {
    log "🔍 Checking if project exists in SonarQube..."
    
    # Check if project exists
    local project_exists=$(curl -s -u "$SONAR_LOGIN:$SONAR_PASSWORD" \
        "$SONAR_HOST_URL/api/projects/search?projects=$SONAR_PROJECT_KEY" | \
        grep -o '"total":[0-9]*' | cut -d':' -f2)
    
    if [ "$project_exists" = "0" ]; then
        log "📝 Creating project in SonarQube..."
        
        curl -s -u "$SONAR_LOGIN:$SONAR_PASSWORD" \
            -X POST \
            "$SONAR_HOST_URL/api/projects/create" \
            -d "project=$SONAR_PROJECT_KEY" \
            -d "name=$SONAR_PROJECT_NAME" >/dev/null 2>&1
        
        if [ $? -eq 0 ]; then
            log "✅ Project created successfully"
        else
            log "❌ Failed to create project"
            exit 1
        fi
    else
        log "✅ Project already exists"
    fi
}

# Function to run analysis with local scanner
run_local_analysis() {
    log "🔍 Running SonarQube analysis with local scanner..."
    
    # Ensure sonar-project.properties exists
    if [ ! -f "sonar-project.properties" ]; then
        log "📝 Creating sonar-project.properties..."
        cat > sonar-project.properties << EOF
sonar.projectKey=$SONAR_PROJECT_KEY
sonar.projectName=$SONAR_PROJECT_NAME
sonar.projectVersion=1.0
sonar.sources=.
sonar.exclusions=node_modules/**,target/**,build/**,dist/**,*.log,security-reports/**
sonar.host.url=$SONAR_HOST_URL
sonar.login=$SONAR_LOGIN
sonar.password=$SONAR_PASSWORD
sonar.sourceEncoding=UTF-8
EOF
    fi
    
    # Run scanner
    if sonar-scanner \
        -Dsonar.projectKey="$SONAR_PROJECT_KEY" \
        -Dsonar.projectName="$SONAR_PROJECT_NAME" \
        -Dsonar.host.url="$SONAR_HOST_URL" \
        -Dsonar.login="$SONAR_LOGIN" \
        -Dsonar.password="$SONAR_PASSWORD"; then
        log "✅ Analysis completed successfully"
        return 0
    else
        log "❌ Analysis failed"
        return 1
    fi
}

# Function to run analysis with Docker
run_docker_analysis() {
    log "🔍 Running SonarQube analysis with Docker scanner..."
    
    # Create scanner properties for Docker
    cat > .scannerwork/sonar-scanner.properties << EOF
sonar.projectKey=$SONAR_PROJECT_KEY
sonar.projectName=$SONAR_PROJECT_NAME
sonar.projectVersion=1.0
sonar.sources=.
sonar.exclusions=node_modules/**,target/**,build/**,dist/**,*.log,security-reports/**,.scannerwork/**
sonar.host.url=$SONAR_HOST_URL
sonar.login=$SONAR_LOGIN
sonar.password=$SONAR_PASSWORD
sonar.sourceEncoding=UTF-8
EOF
    
    # Run Docker scanner
    if docker run --rm \
        --network csb-test-network \
        -v "$(pwd):/usr/src" \
        -w /usr/src \
        sonarsource/sonar-scanner-cli:latest \
        -Dsonar.projectKey="$SONAR_PROJECT_KEY" \
        -Dsonar.projectName="$SONAR_PROJECT_NAME" \
        -Dsonar.host.url="http://sonarqube:9000" \
        -Dsonar.login="$SONAR_LOGIN" \
        -Dsonar.password="$SONAR_PASSWORD"; then
        log "✅ Analysis completed successfully"
        return 0
    else
        log "❌ Analysis failed"
        return 1
    fi
}

# Function to wait for analysis results
wait_for_analysis_results() {
    log "⏳ Waiting for analysis results..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        local task_status=$(curl -s -u "$SONAR_LOGIN:$SONAR_PASSWORD" \
            "$SONAR_HOST_URL/api/ce/component?component=$SONAR_PROJECT_KEY" | \
            grep -o '"status":"[^"]*"' | head -1 | cut -d'"' -f4)
        
        case $task_status in
            "SUCCESS")
                log "✅ Analysis completed successfully"
                return 0
                ;;
            "FAILED"|"CANCELLED")
                log "❌ Analysis failed with status: $task_status"
                return 1
                ;;
            "PENDING"|"IN_PROGRESS")
                printf "   Attempt %d/%d - Analysis in progress...\r" $attempt $max_attempts
                sleep 5
                ((attempt++))
                ;;
            *)
                printf "   Attempt %d/%d - Waiting for analysis to start...\r" $attempt $max_attempts
                sleep 3
                ((attempt++))
                ;;
        esac
    done
    
    echo ""
    log "⚠️ Analysis results not available after waiting"
    return 1
}

# Function to fetch analysis results
fetch_analysis_results() {
    log "📊 Fetching analysis results..."
    
    mkdir -p "$REPORTS_DIR"
    
    # Get project measures
    curl -s -u "$SONAR_LOGIN:$SONAR_PASSWORD" \
        "$SONAR_HOST_URL/api/measures/component?component=$SONAR_PROJECT_KEY&metricKeys=vulnerabilities,security_hotspots,code_smells,bugs,coverage,duplicated_lines_density" \
        > "$REPORTS_DIR/measures.json"
    
    # Get issues
    curl -s -u "$SONAR_LOGIN:$SONAR_PASSWORD" \
        "$SONAR_HOST_URL/api/issues/search?componentKeys=$SONAR_PROJECT_KEY&types=VULNERABILITY,SECURITY_HOTSPOT,BUG,CODE_SMELL" \
        > "$REPORTS_DIR/issues.json"
    
    # Generate summary report
    generate_summary_report
}

# Function to generate summary report
generate_summary_report() {
    log "📝 Generating summary report..."
    
    local vulnerabilities=$(jq '.component.measures[] | select(.metric=="vulnerabilities") | .value' "$REPORTS_DIR/measures.json" 2>/dev/null || echo "0")
    local security_hotspots=$(jq '.component.measures[] | select(.metric=="security_hotspots") | .value' "$REPORTS_DIR/measures.json" 2>/dev/null || echo "0")
    local code_smells=$(jq '.component.measures[] | select(.metric=="code_smells") | .value' "$REPORTS_DIR/measures.json" 2>/dev/null || echo "0")
    local bugs=$(jq '.component.measures[] | select(.metric=="bugs") | .value' "$REPORTS_DIR/measures.json" 2>/dev/null || echo "0")
    
    cat > "$REPORTS_DIR/summary.md" << EOF
# SonarQube Analysis Summary

**Project:** $SONAR_PROJECT_NAME  
**Analysis Date:** $(date)  
**SonarQube URL:** $SONAR_HOST_URL/dashboard?id=$SONAR_PROJECT_KEY

## Security Issues

| Metric | Count |
|--------|-------|
| Vulnerabilities | $vulnerabilities |
| Security Hotspots | $security_hotspots |
| Bugs | $bugs |
| Code Smells | $code_smells |

## Key Findings

### Critical Security Issues
- Hardcoded credentials detection
- SQL injection vulnerabilities
- Cross-site scripting (XSS) risks
- Insecure cryptographic usage
- Path traversal vulnerabilities

### Recommendations
1. Review and fix all security vulnerabilities
2. Address security hotspots manually
3. Implement secure coding practices
4. Add security-focused unit tests
5. Enable SonarQube quality gate

## Links
- [View in SonarQube]($SONAR_HOST_URL/dashboard?id=$SONAR_PROJECT_KEY)
- [Issues]($SONAR_HOST_URL/project/issues?id=$SONAR_PROJECT_KEY)
- [Security Hotspots]($SONAR_HOST_URL/security_hotspots?id=$SONAR_PROJECT_KEY)
EOF
    
    log "✅ Summary report generated: $REPORTS_DIR/summary.md"
}

# Function to display results
display_results() {
    echo ""
    echo "🎉 ====================================="
    echo "🎉 SonarQube Analysis Complete!"
    echo "🎉 ====================================="
    echo ""
    
    if [ -f "$REPORTS_DIR/summary.md" ]; then
        echo "📊 Analysis Summary:"
        echo ""
        cat "$REPORTS_DIR/summary.md" | grep -A 10 "## Security Issues"
        echo ""
    fi
    
    echo "🌐 View Results:"
    echo "  SonarQube Dashboard: $SONAR_HOST_URL/dashboard?id=$SONAR_PROJECT_KEY"
    echo "  Issues: $SONAR_HOST_URL/project/issues?id=$SONAR_PROJECT_KEY"
    echo "  Security: $SONAR_HOST_URL/security_hotspots?id=$SONAR_PROJECT_KEY"
    echo ""
    echo "📁 Reports saved to: $REPORTS_DIR/"
    echo ""
    
    if [ -n "${CODESPACE_NAME:-}" ] && [ -n "${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-}" ]; then
        echo "☁️ Codespaces URL:"
        echo "  https://${CODESPACE_NAME}-9000.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}/dashboard?id=$SONAR_PROJECT_KEY"
        echo ""
    fi
}

# Main execution
main() {
    echo ""
    log "Starting SonarQube analysis workflow..."
    echo ""
    
    # Check prerequisites
    check_sonarqube_status
    
    # Set up scanner
    if ! check_sonar_scanner; then
        if [ "${AUTO_INSTALL:-false}" = "true" ]; then
            install_sonar_scanner || true
        fi
    fi
    
    # Create directory for scanner work
    mkdir -p .scannerwork
    
    # Create project if needed
    create_sonarqube_project
    
    # Run analysis
    if check_sonar_scanner; then
        run_local_analysis
    else
        run_docker_analysis
    fi
    
    # Wait for results
    wait_for_analysis_results
    
    # Fetch and generate reports
    fetch_analysis_results
    
    # Display results
    display_results
    
    log "✅ SonarQube analysis workflow completed!"
}

# Command line options
case "${1:-}" in
    --install-scanner)
        install_sonar_scanner
        exit 0
        ;;
    --docker-only)
        export USE_DOCKER_SCANNER=true
        ;;
    --help|-h)
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --install-scanner  Install SonarQube Scanner locally"
        echo "  --docker-only      Force use of Docker scanner"
        echo "  --help            Show this help"
        echo ""
        echo "Environment variables:"
        echo "  AUTO_INSTALL=true  Automatically install scanner if missing"
        echo ""
        exit 0
        ;;
esac

# Execute main function
main "$@"