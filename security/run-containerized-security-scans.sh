#!/bin/bash
# Enhanced security scan script using containerized tools

echo "🔒 CSB DevSecOps Containerized Security Scanning"
echo "================================================"

# Create security reports directory
mkdir -p security-reports/{semgrep,trufflehog,zap,trivy,snyk}

# Function to check if a service is running
check_service_running() {
    local service=$1
    if docker-compose ps --services --filter "status=running" | grep -q "^${service}$"; then
        return 0
    else
        return 1
    fi
}

# Check if main applications are running
echo "📊 Checking application services..."
services=("spring-boot-api" "flask-api" "django-app" "node-express" "dotnet-api")
running_services=()

for service in "${services[@]}"; do
    if check_service_running "$service"; then
        echo "✅ $service is running"
        running_services+=("$service")
    else
        echo "⚠️  $service is not running"
    fi
done

if [ ${#running_services[@]} -eq 0 ]; then
    echo ""
    echo "❌ No application services are running!"
    echo "💡 Start services first: docker-compose up -d"
    exit 1
fi

echo ""
echo "🔍 Running Security Scans..."
echo "============================"

# 1. TruffleHog Secret Detection
echo ""
echo "🔐 1. Running TruffleHog secret detection..."
mkdir -p security-reports/trufflehog
echo "   Scanning for verified secrets..."
docker-compose run --rm trufflehog > security-reports/trufflehog/secrets-verified.json
echo "   Scanning for all potential secrets..."
docker-compose run --rm trufflehog-all > security-reports/trufflehog/secrets-all.json

# 2. Semgrep Static Analysis
echo ""
echo "🔍 2. Running Semgrep static analysis..."
mkdir -p security-reports/semgrep
if [ -n "$SEMGREP_APP_TOKEN" ]; then
    echo "   Using Semgrep App token for enhanced rules"
else
    echo "   ⚠️  SEMGREP_APP_TOKEN not set - using free rules only"
fi
echo "   Running SARIF format scan..."
docker-compose run --rm semgrep
echo "   Running JSON format scan..."
docker-compose run --rm semgrep-json

# 3. Trivy Filesystem and Dependency Scan
echo ""
echo "🔍 3. Running Trivy vulnerability scanning..."
mkdir -p security-reports/trivy
echo "   Running filesystem scan (JSON format)..."
docker-compose run --rm trivy
echo "   Running filesystem scan (SARIF format)..."
docker-compose run --rm trivy-sarif

# 4. Snyk Dependency Scanning (if token available)
echo ""
echo "📦 4. Running Snyk dependency scanning..."
if [ -n "$SNYK_TOKEN" ]; then
    docker-compose run --rm snyk
else
    echo "   ⚠️  SNYK_TOKEN not set - skipping Snyk scan"
    echo "   💡 Set SNYK_TOKEN environment variable to enable"
fi

# 5. OWASP ZAP Dynamic Scanning (only if services are running)
if [ ${#running_services[@]} -gt 0 ]; then
    echo ""
    echo "🕷️ 5. Running OWASP ZAP dynamic scanning..."
    echo "   Scanning running services: ${running_services[*]}"
    docker-compose run --rm zap
else
    echo ""
    echo "⚠️  5. Skipping OWASP ZAP - no services running"
fi

echo ""
echo "📊 Generating Security Summary..."
echo "================================"

# Count findings
trufflehog_findings=$(find security-reports/trufflehog -name "*.json" -exec jq '. | length' {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
semgrep_findings=$(find security-reports/semgrep -name "*.json" -exec jq '.results | length' {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')

echo "🔐 TruffleHog Secret Detection: $trufflehog_findings secrets found"
echo "🔍 Semgrep Static Analysis: $semgrep_findings issues found"
echo "🔍 Trivy Vulnerability Scan: Results in security-reports/trivy/"
if [ -n "$SNYK_TOKEN" ]; then
    echo "📦 Snyk Dependency Scan: Results in security-reports/snyk/"
else
    echo "📦 Snyk Dependency Scan: Skipped (no token)"
fi
echo "🕷️ OWASP ZAP Dynamic Scan: Results in security-reports/zap/"

echo ""
echo "📁 Security Reports Location:"
echo "=============================="
echo "📂 All reports: ./security-reports/"
echo "   ├── 🔐 trufflehog/     - Secret detection results"
echo "   ├── 🔍 semgrep/        - Static analysis results" 
echo "   ├── 🔍 trivy/          - Vulnerability scan results"
echo "   ├── 📦 snyk/           - Dependency scan results"
echo "   └── 🕷️ zap/            - Dynamic scan results"

echo ""
echo "🌐 Security Dashboard:"
echo "======================"
echo "Start dashboard: docker-compose --profile security up -d security-dashboard"
echo "View reports:    http://localhost:9000"

echo ""
echo "💡 Pro Tips:"
echo "============"
echo "• Set SEMGREP_APP_TOKEN for enhanced Semgrep rules"
echo "• Set SNYK_TOKEN for dependency vulnerability scanning"
echo "• Use profiles: docker-compose --profile security up -d"
echo "• Run all tools: docker-compose --profile all up -d"

echo ""
echo "✅ Security scanning complete!"
echo "📋 Expected findings: 100+ issues (this is intentional for testing)"