#!/bin/bash
# Complete CSB DevSecOps Environment - Single Scalable Script
# Handles Docker permissions, setup, service startup, security scanning, and dashboard

set -e

echo "🚀 CSB DevSecOps Complete Environment"
echo "===================================="

# Configuration
SECURITY_REPORTS_DIR="security-reports"
DASHBOARD_DIR="security/dashboard"
SCAN_ONLY=false

# Expected findings for comparison
declare -A EXPECTED_FINDINGS=(
    ["semgrep"]=40
    ["trufflehog"]=15
    ["trivy"]=20
    ["snyk"]=30
    ["zap"]=15
)

declare -A ACTUAL_FINDINGS=()
declare -A SCAN_STATUS=()

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --scan-only)
            SCAN_ONLY=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--scan-only] [--help]"
            echo "  --scan-only    Run security scans only (skip service startup)"
            echo "  --help         Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Function to log with timestamp
log() {
    echo "[$(date '+%H:%M:%S')] $1"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to fix Docker permissions in Codespaces
fix_docker_permissions() {
    log "🔧 Checking Docker permissions..."
    
    # Test if Docker works without issues
    if docker ps >/dev/null 2>&1; then
        log "✅ Docker is working correctly"
        return 0
    fi
    
    log "⚠️ Docker permission issue detected - applying automatic fix..."
    
    # Check if we're in Codespaces
    if [ -n "${CODESPACE_NAME:-}" ]; then
        log "🌐 GitHub Codespaces detected - applying Codespaces-specific fixes"
    fi
    
    # Fix 1: Add user to docker group
    log "Adding $(whoami) to docker group..."
    sudo usermod -aG docker $(whoami) 2>/dev/null || true
    
    # Fix 2: Set proper permissions on Docker socket
    log "Setting Docker socket permissions..."
    sudo chmod 666 /var/run/docker.sock 2>/dev/null || true
    
    # Fix 3: Restart Docker service
    log "Restarting Docker service..."
    sudo systemctl restart docker 2>/dev/null || true
    sleep 3
    
    # Fix 4: Start Docker service if not running
    if ! sudo systemctl is-active docker >/dev/null 2>&1; then
        log "Starting Docker service..."
        sudo systemctl start docker 2>/dev/null || true
        sleep 3
    fi
    
    # Test Docker access again
    if docker ps >/dev/null 2>&1; then
        log "✅ Docker permissions fixed successfully"
        return 0
    else
        log "❌ Docker permission fix failed"
        echo ""
        echo "🔧 Manual Docker Fix Required:"
        echo "1. Run: sudo chmod 666 /var/run/docker.sock"
        echo "2. Run: sudo usermod -aG docker \$(whoami)"
        echo "3. Run: sudo systemctl restart docker"
        echo "4. Close and reopen your terminal"
        echo "5. Run this script again"
        echo ""
        exit 1
    fi
}

# Function to wait for service
wait_for_service() {
    local service=$1
    local port=$2
    local max_attempts=30
    local attempt=1
    
    log "⏳ Waiting for $service to be ready on port $port..."
    
    while [ $attempt -le $max_attempts ]; do
        if nc -z localhost $port >/dev/null 2>&1; then
            log "✅ $service is ready!"
            return 0
        fi
        echo "   Attempt $attempt/$max_attempts - $service not ready yet..."
        sleep 2
        ((attempt++))
    done
    
    log "❌ $service failed to become ready after $((max_attempts * 2)) seconds"
    return 1
}

# Function to calculate coverage percentage
calculate_coverage() {
    local actual=$1
    local expected=$2
    if [ $actual -ge $expected ]; then
        echo "100"
    else
        echo $(( (actual * 100) / expected ))
    fi
}

# Function to get status based on coverage
get_status() {
    local coverage=$1
    if [ $coverage -ge 90 ]; then
        echo "EXCELLENT"
    elif [ $coverage -ge 70 ]; then
        echo "GOOD"
    elif [ $coverage -ge 50 ]; then
        echo "PARTIAL"
    else
        echo "LOW"
    fi
}

# Function to clean and setup environment
setup_environment() {
    log "📁 Setting up environment structure..."
    
    # Clean up any existing conflicts
    log "🧹 Cleaning up any existing conflicts..."
    rm -rf "$DASHBOARD_DIR/index.html" 2>/dev/null || true
    rm -rf "$DASHBOARD_DIR" 2>/dev/null || true
    
    # Create comprehensive directory structure
    mkdir -p "$SECURITY_REPORTS_DIR"/{semgrep,trufflehog,trivy,snyk,zap,general,comparison}
    mkdir -p "$DASHBOARD_DIR"
    mkdir -p scripts/security
    mkdir -p databases/{postgresql,mysql,oracle}
    
    # Create PostgreSQL initialization script
    if [ ! -f databases/postgresql/init-multiple-databases.sh ]; then
        mkdir -p databases/postgresql
        cat > databases/postgresql/init-multiple-databases.sh << 'PGEOF'
#!/bin/bash
set -e
set -u

function create_user_and_database() {
    local database=$1
    echo "Creating user and database '$database'"
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
        CREATE DATABASE $database;
        GRANT ALL PRIVILEGES ON DATABASE $database TO $POSTGRES_USER;
EOSQL
}

if [ -n "$POSTGRES_MULTIPLE_DATABASES" ]; then
    echo "Creating multiple databases: $POSTGRES_MULTIPLE_DATABASES"
    for db in $(echo $POSTGRES_MULTIPLE_DATABASES | tr ',' ' '); do
        create_user_and_database $db
    done
    echo "Multiple databases created"
fi
PGEOF
        chmod +x databases/postgresql/init-multiple-databases.sh
    fi
    
    # Create seed data script
    if [ ! -f databases/postgresql/seed-data.sql ]; then
        cat > databases/postgresql/seed-data.sql << 'SQLEOF'
-- Seed data for security testing
\c csbdb;
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50),
    password VARCHAR(100),
    email VARCHAR(100),
    name VARCHAR(100)
);

INSERT INTO users (username, password, email, name) VALUES 
('admin', 'admin123', 'admin@csb.com', 'Administrator'),
('testuser', 'password', 'test@csb.com', 'Test User'),
('john.doe', 'secret123', 'john@csb.com', 'John Doe');

\c flaskdb;
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50),
    password VARCHAR(100),
    email VARCHAR(100),
    name VARCHAR(100)
);

INSERT INTO users (username, password, email, name) VALUES 
('flask_admin', 'flask123', 'flask@csb.com', 'Flask Admin'),
('flask_user', 'flask_password', 'flaskuser@csb.com', 'Flask User');

\c springdb;
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50),
    password VARCHAR(100),
    email VARCHAR(100),
    name VARCHAR(100)
);

INSERT INTO users (username, password, email, name) VALUES 
('spring_admin', 'spring123', 'spring@csb.com', 'Spring Admin'),
('spring_user', 'spring_password', 'springuser@csb.com', 'Spring User');

\c dotnetdb;
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50),
    password VARCHAR(100),
    email VARCHAR(100),
    name VARCHAR(100)
);

INSERT INTO users (username, password, email, name) VALUES 
('dotnet_admin', 'dotnet123', 'dotnet@csb.com', '.NET Admin'),
('dotnet_user', 'dotnet_password', 'dotnetuser@csb.com', '.NET User');

\c nodedb;
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50),
    password VARCHAR(100),
    email VARCHAR(100),
    name VARCHAR(100)
);

INSERT INTO users (username, password, email, name) VALUES 
('node_admin', 'node123', 'node@csb.com', 'Node Admin'),
('node_user', 'node_password', 'nodeuser@csb.com', 'Node User');
SQLEOF
    fi
    
    # Create enhanced security dashboard
    log "🎯 Creating enhanced security dashboard..."
    cat > "$DASHBOARD_DIR/index.html" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CSB DevSecOps Security Dashboard</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            color: #333;
        }
        
        .header {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(10px);
            padding: 20px;
            text-align: center;
            box-shadow: 0 2px 20px rgba(0,0,0,0.1);
        }
        
        .header h1 { color: #2c3e50; margin-bottom: 10px; font-size: 2.5em; }
        .header p { color: #7f8c8d; font-size: 1.2em; }
        
        .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
        
        .warning {
            background: linear-gradient(45deg, #e74c3c, #c0392b);
            color: white; padding: 15px; border-radius: 10px; margin: 20px 0;
            text-align: center; box-shadow: 0 5px 15px rgba(231, 76, 60, 0.3);
        }
        
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px; margin: 30px 0;
        }
        
        .stat-card {
            background: rgba(255, 255, 255, 0.95); padding: 20px; border-radius: 15px;
            text-align: center; box-shadow: 0 10px 30px rgba(0,0,0,0.1);
            transition: transform 0.3s ease, box-shadow 0.3s ease;
        }
        
        .stat-card:hover { transform: translateY(-5px); box-shadow: 0 15px 40px rgba(0,0,0,0.2); }
        
        .stat-number { font-size: 3em; font-weight: bold; margin-bottom: 10px; }
        
        .critical { color: #e74c3c; }
        .high { color: #f39c12; }
        .medium { color: #f1c40f; }
        .low { color: #27ae60; }
        
        .comparison-table {
            background: rgba(255, 255, 255, 0.95); border-radius: 15px; padding: 25px;
            margin: 30px 0; box-shadow: 0 10px 30px rgba(0,0,0,0.1);
        }
        
        .comparison-table h2 { color: #2c3e50; margin-bottom: 20px; text-align: center; }
        
        table { width: 100%; border-collapse: collapse; margin-top: 15px; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ecf0f1; }
        th { background: #34495e; color: white; font-weight: bold; }
        
        .status-excellent { color: #27ae60; font-weight: bold; }
        .status-good { color: #2ecc71; font-weight: bold; }
        .status-partial { color: #f39c12; font-weight: bold; }
        .status-low { color: #e74c3c; font-weight: bold; }
        
        .tools-grid {
            display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px; margin: 30px 0;
        }
        
        .tool-card {
            background: rgba(255, 255, 255, 0.95); padding: 25px; border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.1); transition: all 0.3s ease;
        }
        
        .tool-card:hover { transform: translateY(-5px); box-shadow: 0 15px 40px rgba(0,0,0,0.2); }
        
        .tool-card h3 { color: #2c3e50; margin-bottom: 15px; font-size: 1.4em; display: flex; align-items: center; }
        .tool-card h3 .icon { font-size: 1.5em; margin-right: 10px; }
        .tool-card p { color: #7f8c8d; margin-bottom: 20px; line-height: 1.6; }
        
        .links { display: flex; flex-wrap: wrap; gap: 10px; }
        
        .btn {
            padding: 8px 16px; background: linear-gradient(45deg, #3498db, #2980b9);
            color: white; text-decoration: none; border-radius: 25px; font-size: 0.9em;
            transition: all 0.3s ease; box-shadow: 0 3px 10px rgba(52, 152, 219, 0.3);
        }
        
        .btn:hover { transform: translateY(-2px); box-shadow: 0 5px 15px rgba(52, 152, 219, 0.4); }
        
        .refresh-btn {
            position: fixed; bottom: 30px; right: 30px; width: 60px; height: 60px;
            border-radius: 50%; background: linear-gradient(45deg, #3498db, #2980b9);
            color: white; border: none; font-size: 1.5em; cursor: pointer;
            box-shadow: 0 5px 15px rgba(52, 152, 219, 0.4); transition: all 0.3s ease;
        }
        
        .refresh-btn:hover { transform: scale(1.1); box-shadow: 0 8px 25px rgba(52, 152, 219, 0.6); }
        
        @media (max-width: 768px) {
            .stats-grid { grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); }
            .tools-grid { grid-template-columns: 1fr; }
            .header h1 { font-size: 2em; }
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🔒 CSB DevSecOps Security Dashboard</h1>
        <p>Comprehensive security analysis for intentionally vulnerable applications</p>
        <p><strong>Last Updated:</strong> <span id="lastUpdate"></span></p>
    </div>

    <div class="container">
        <div class="warning">
            <strong>⚠️ WARNING:</strong> This dashboard shows results from intentionally vulnerable applications.
            Expected findings: 120+ security issues for comprehensive tool validation.
        </div>

        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-number critical" id="criticalCount">25+</div>
                <div>Critical Issues</div>
            </div>
            <div class="stat-card">
                <div class="stat-number high" id="highCount">40+</div>
                <div>High Issues</div>
            </div>
            <div class="stat-card">
                <div class="stat-number medium" id="mediumCount">35+</div>
                <div>Medium Issues</div>
            </div>
            <div class="stat-card">
                <div class="stat-number low" id="lowCount">20+</div>
                <div>Low Issues</div>
            </div>
        </div>

        <div class="comparison-table">
            <h2>📊 Expected vs Actual Findings</h2>
            <table>
                <thead>
                    <tr>
                        <th>Security Tool</th>
                        <th>Expected</th>
                        <th>Actual</th>
                        <th>Coverage</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>🔍 Semgrep (SAST)</td>
                        <td>40+</td>
                        <td id="semgrepActual">--</td>
                        <td id="semgrepCoverage">--</td>
                        <td id="semgrepStatus">--</td>
                    </tr>
                    <tr>
                        <td>🔐 TruffleHog (Secrets)</td>
                        <td>15+</td>
                        <td id="trufflehogActual">--</td>
                        <td id="trufflehogCoverage">--</td>
                        <td id="trufflehogStatus">--</td>
                    </tr>
                    <tr>
                        <td>🔍 Trivy (Vulnerabilities)</td>
                        <td>20+</td>
                        <td id="trivyActual">--</td>
                        <td id="trivyCoverage">--</td>
                        <td id="trivyStatus">--</td>
                    </tr>
                    <tr>
                        <td>📦 Snyk (Dependencies)</td>
                        <td>30+</td>
                        <td id="snykActual">--</td>
                        <td id="snykCoverage">--</td>
                        <td id="snykStatus">--</td>
                    </tr>
                    <tr>
                        <td>🕷️ OWASP ZAP (DAST)</td>
                        <td>15+</td>
                        <td id="zapActual">--</td>
                        <td id="zapCoverage">--</td>
                        <td id="zapStatus">--</td>
                    </tr>
                </tbody>
            </table>
        </div>

        <div class="tools-grid">
            <div class="tool-card">
                <h3><span class="icon">🔐</span>TruffleHog - Secret Detection</h3>
                <p>Scans for hardcoded secrets, API keys, and credentials in source code.</p>
                <div class="links">
                    <a href="/reports/trufflehog/" class="btn">Browse Results</a>
                    <a href="/reports/trufflehog/secrets-verified.json" class="btn">Verified (JSON)</a>
                    <a href="/reports/trufflehog/secrets-all.json" class="btn">All Findings</a>
                </div>
            </div>

            <div class="tool-card">
                <h3><span class="icon">🔍</span>Semgrep - Static Analysis</h3>
                <p>Static application security testing (SAST) with custom CSB rules.</p>
                <div class="links">
                    <a href="/reports/semgrep/" class="btn">Browse Results</a>
                    <a href="/reports/semgrep/comprehensive-scan.json" class="btn">JSON Report</a>
                    <a href="/reports/semgrep/comprehensive-scan.sarif" class="btn">SARIF Format</a>
                </div>
            </div>

            <div class="tool-card">
                <h3><span class="icon">🔍</span>Trivy - Vulnerability Scanner</h3>
                <p>Filesystem and dependency vulnerability scanning.</p>
                <div class="links">
                    <a href="/reports/trivy/" class="btn">Browse Results</a>
                    <a href="/reports/trivy/filesystem-scan.json" class="btn">JSON Report</a>
                    <a href="/reports/trivy/filesystem-scan.sarif" class="btn">SARIF Format</a>
                </div>
            </div>

            <div class="tool-card">
                <h3><span class="icon">📦</span>Snyk - Dependency Scanner</h3>
                <p>Dependency vulnerability scanning and license compliance.</p>
                <div class="links">
                    <a href="/reports/snyk/" class="btn">Browse Results</a>
                    <a href="/reports/snyk/dependencies-scan.json" class="btn">JSON Report</a>
                </div>
            </div>

            <div class="tool-card">
                <h3><span class="icon">🕷️</span>OWASP ZAP - Dynamic Scanner</h3>
                <p>Dynamic application security testing (DAST) of running services.</p>
                <div class="links">
                    <a href="/reports/zap/" class="btn">Browse Results</a>
                    <a href="/reports/zap/zap-baseline-report.html" class="btn">Spring Boot</a>
                    <a href="/reports/zap/zap-flask-report.html" class="btn">Flask</a>
                    <a href="/reports/zap/zap-django-report.html" class="btn">Django</a>
                </div>
            </div>

            <div class="tool-card">
                <h3><span class="icon">📊</span>Application Status</h3>
                <p>Live status of all test applications and databases.</p>
                <div class="links">
                    <a href="http://localhost:3000" class="btn" target="_blank">React App</a>
                    <a href="http://localhost:4200" class="btn" target="_blank">Angular App</a>
                    <a href="http://localhost:8080/api/health" class="btn" target="_blank">Spring Boot</a>
                    <a href="http://localhost:5000" class="btn" target="_blank">Flask API</a>
                    <a href="http://localhost:8000" class="btn" target="_blank">Django API</a>
                    <a href="http://localhost:8081" class="btn" target="_blank">Adminer</a>
                </div>
            </div>
        </div>

        <div style="background: rgba(255, 255, 255, 0.95); padding: 25px; border-radius: 15px; margin: 30px 0;">
            <h3>📋 Quick Commands</h3>
            <p><strong>Restart All:</strong> <code>./start-with-dependencies.sh</code></p>
            <p><strong>Security Scan Only:</strong> <code>./start-with-dependencies.sh --scan-only</code></p>
            <p><strong>Check Status:</strong> <code>docker-compose ps</code></p>
            <p><strong>View Logs:</strong> <code>docker-compose logs [service-name]</code></p>
        </div>
    </div>

    <button class="refresh-btn" onclick="refreshData()" title="Refresh Data">🔄</button>

    <script>
        document.getElementById('lastUpdate').textContent = new Date().toLocaleString();

        async function fetchJSON(url) {
            try {
                const response = await fetch(url);
                if (response.ok) return await response.json();
            } catch (error) {
                console.log(`Could not fetch ${url}:`, error);
            }
            return null;
        }

        function calculateCoverage(actual, expected) {
            const coverage = Math.min(100, Math.round((actual / expected) * 100));
            return coverage >= expected ? '✅ ' + coverage + '%' : '⚠️ ' + coverage + '%';
        }

        function getStatus(actual, expected) {
            const coverage = (actual / expected) * 100;
            if (coverage >= 90) return '<span class="status-excellent">✅ EXCELLENT</span>';
            if (coverage >= 70) return '<span class="status-good">🟢 GOOD</span>';
            if (coverage >= 50) return '<span class="status-partial">⚠️ PARTIAL</span>';
            return '<span class="status-low">❌ LOW</span>';
        }

        async function refreshData() {
            console.log('Refreshing dashboard data...');
            document.getElementById('lastUpdate').textContent = new Date().toLocaleString();

            const semgrepData = await fetchJSON('/reports/semgrep/comprehensive-scan.json');
            if (semgrepData?.results) {
                const count = semgrepData.results.length;
                document.getElementById('semgrepActual').textContent = count;
                document.getElementById('semgrepCoverage').textContent = calculateCoverage(count, 40);
                document.getElementById('semgrepStatus').innerHTML = getStatus(count, 40);
            }

            const trufflehogData = await fetchJSON('/reports/trufflehog/secrets-verified.json');
            if (trufflehogData) {
                const count = Array.isArray(trufflehogData) ? trufflehogData.length : 0;
                document.getElementById('trufflehogActual').textContent = count;
                document.getElementById('trufflehogCoverage').textContent = calculateCoverage(count, 15);
                document.getElementById('trufflehogStatus').innerHTML = getStatus(count, 15);
            }

            const trivyData = await fetchJSON('/reports/trivy/filesystem-scan.json');
            if (trivyData?.Results) {
                let count = 0;
                trivyData.Results.forEach(result => {
                    if (result.Vulnerabilities) count += result.Vulnerabilities.length;
                });
                document.getElementById('trivyActual').textContent = count;
                document.getElementById('trivyCoverage').textContent = calculateCoverage(count, 20);
                document.getElementById('trivyStatus').innerHTML = getStatus(count, 20);
            }

            const snykData = await fetchJSON('/reports/snyk/dependencies-scan.json');
            if (snykData?.vulnerabilities) {
                const count = snykData.vulnerabilities.length;
                document.getElementById('snykActual').textContent = count;
                document.getElementById('snykCoverage').textContent = calculateCoverage(count, 30);
                document.getElementById('snykStatus').innerHTML = getStatus(count, 30);
            }
        }

        setInterval(refreshData, 30000);
        refreshData();
    </script>
</body>
</html>
HTMLEOF

    # Verify the dashboard file was created
    if [ ! -f "$DASHBOARD_DIR/index.html" ]; then
        log "❌ Failed to create dashboard HTML file"
        exit 1
    fi
    
    log "✅ Environment setup complete"
}

# Function to start services in proper order
start_services() {
    if [ "$SCAN_ONLY" = true ]; then
        log "⏭️ Skipping service startup (scan-only mode)"
        return 0
    fi
    
    log "🚀 Starting CSB DevSecOps Application Stack"
    
    # Create Docker network
    docker network create csb-test-network 2>/dev/null || true
    
    echo ""
    log "📊 Step 1: Starting databases..."
    docker-compose up -d postgres mysql
    log "Waiting for databases to initialize..."
    sleep 30
    
    # Wait for databases to be ready
    wait_for_service "PostgreSQL" 5432
    wait_for_service "MySQL" 3306
    
    echo ""
    log "⚙️ Step 2: Starting backend applications..."
    docker-compose up -d spring-boot-api django-app flask-api node-express dotnet-api php-drupal
    log "Waiting for backend services..."
    sleep 20
    
    echo ""
    log "🖥️ Step 3: Starting frontend applications..."
    docker-compose up -d react-app angular-app
    sleep 10
    
    echo ""
    log "🛠️ Step 4: Starting support services..."
    docker-compose up -d adminer
    sleep 5
    
    # Verify services are ready
    echo ""
    log "🔍 Verifying service readiness..."
    
    local services=("PostgreSQL:5432" "MySQL:3306" "Spring Boot:8080" "Django:8000" "Flask:5000" "React:3000")
    local ready_count=0
    
    for service_port in "${services[@]}"; do
        local service=$(echo $service_port | cut -d: -f1)
        local port=$(echo $service_port | cut -d: -f2)
        
        if nc -z localhost $port 2>/dev/null; then
            log "✅ $service is ready"
            ((ready_count++))
        else
            log "⚠️ $service is not responding"
        fi
    done
    
    log "📊 Services ready: $ready_count/${#services[@]}"
}

# Function to run comprehensive security scans
run_security_scans() {
    log "🔒 Running comprehensive security analysis..."
    
    # Run containerized security scans
    log "🔍 Starting security tool containers..."
    
    # Semgrep scan
    log "Running Semgrep SAST analysis..."
    if docker-compose run --rm semgrep >/dev/null 2>&1; then
        SCAN_STATUS["semgrep"]="SUCCESS"
        if [ -f "$SECURITY_REPORTS_DIR/semgrep/comprehensive-scan.json" ]; then
            local count=$(jq '.results | length' "$SECURITY_REPORTS_DIR/semgrep/comprehensive-scan.json" 2>/dev/null || echo "0")
            ACTUAL_FINDINGS["semgrep"]=$count
            log "✅ Semgrep: $count findings"
        else
            ACTUAL_FINDINGS["semgrep"]=0
        fi
    else
        SCAN_STATUS["semgrep"]="FAILED"
        ACTUAL_FINDINGS["semgrep"]=0
        log "❌ Semgrep scan failed"
    fi
    
    # TruffleHog scan
    log "Running TruffleHog secret detection..."
    if docker-compose run --rm trufflehog >/dev/null 2>&1; then
        SCAN_STATUS["trufflehog"]="SUCCESS"
        if [ -f "$SECURITY_REPORTS_DIR/trufflehog/secrets-verified.json" ]; then
            local count=$(jq -s 'length' "$SECURITY_REPORTS_DIR/trufflehog/secrets-verified.json" 2>/dev/null || echo "0")
            ACTUAL_FINDINGS["trufflehog"]=$count
            log "✅ TruffleHog: $count verified secrets"
        else
            ACTUAL_FINDINGS["trufflehog"]=0
        fi
    else
        SCAN_STATUS["trufflehog"]="FAILED"
        ACTUAL_FINDINGS["trufflehog"]=0
        log "❌ TruffleHog scan failed"
    fi
    
    # Trivy scan
    log "Running Trivy vulnerability analysis..."
    if docker-compose run --rm trivy >/dev/null 2>&1; then
        SCAN_STATUS["trivy"]="SUCCESS"
        docker-compose run --rm trivy-sarif >/dev/null 2>&1 || true
        if [ -f "$SECURITY_REPORTS_DIR/trivy/filesystem-scan.json" ]; then
            local count=$(jq '[.Results[]? | select(.Vulnerabilities) | .Vulnerabilities | length] | add // 0' "$SECURITY_REPORTS_DIR/trivy/filesystem-scan.json" 2>/dev/null || echo "0")
            ACTUAL_FINDINGS["trivy"]=$count
            log "✅ Trivy: $count vulnerabilities"
        else
            ACTUAL_FINDINGS["trivy"]=0
        fi
    else
        SCAN_STATUS["trivy"]="FAILED"
        ACTUAL_FINDINGS["trivy"]=0
        log "❌ Trivy scan failed"
    fi
    
    # Snyk scan (if token available)
    if [ -n "${SNYK_TOKEN:-}" ]; then
        log "Running Snyk dependency analysis..."
        if docker-compose run --rm snyk >/dev/null 2>&1; then
            SCAN_STATUS["snyk"]="SUCCESS"
            if [ -f "$SECURITY_REPORTS_DIR/snyk/dependencies-scan.json" ]; then
                local count=$(jq '.vulnerabilities | length' "$SECURITY_REPORTS_DIR/snyk/dependencies-scan.json" 2>/dev/null || echo "0")
                ACTUAL_FINDINGS["snyk"]=$count
                log "✅ Snyk: $count dependencies"
            else
                ACTUAL_FINDINGS["snyk"]=0
            fi
        else
            SCAN_STATUS["snyk"]="FAILED"
            ACTUAL_FINDINGS["snyk"]=0
            log "❌ Snyk scan failed"
        fi
    else
        SCAN_STATUS["snyk"]="SKIPPED"
        ACTUAL_FINDINGS["snyk"]=0
        log "⚠️ SNYK_TOKEN not set - skipping Snyk scan"
    fi
    
    # OWASP ZAP scan (if services are running)
    local running_services=($(docker-compose ps --services --filter "status=running" | grep -E "(spring-boot-api|flask-api|django-app)" || true))
    if [ ${#running_services[@]} -gt 0 ]; then
        log "Running OWASP ZAP dynamic analysis..."
        if docker-compose run --rm zap >/dev/null 2>&1; then
            SCAN_STATUS["zap"]="SUCCESS"
            local total_findings=0
            for report in "$SECURITY_REPORTS_DIR/zap"/*.json; do
                if [ -f "$report" ]; then
                    local count=$(jq '.site[0].alerts | length' "$report" 2>/dev/null || echo "0")
                    total_findings=$((total_findings + count))
                fi
            done
            ACTUAL_FINDINGS["zap"]=$total_findings
            log "✅ ZAP: $total_findings web app issues"
        else
            SCAN_STATUS["zap"]="FAILED"
            ACTUAL_FINDINGS["zap"]=0
            log "❌ ZAP scan failed"
        fi
    else
        SCAN_STATUS["zap"]="NO_TARGETS"
        ACTUAL_FINDINGS["zap"]=0
        log "⚠️ ZAP: No running services to scan"
    fi
    
    # Generate comparison report
    generate_comparison_report
}

# Function to generate scan comparison
generate_comparison_report() {
    log "📊 Generating expected vs actual comparison..."
    
    local comparison_file="$SECURITY_REPORTS_DIR/comparison/expected-vs-actual.json"
    mkdir -p "$SECURITY_REPORTS_DIR/comparison"
    
    # Calculate totals
    local total_expected=$(( ${EXPECTED_FINDINGS[semgrep]} + ${EXPECTED_FINDINGS[trufflehog]} + ${EXPECTED_FINDINGS[trivy]} + ${EXPECTED_FINDINGS[snyk]} + ${EXPECTED_FINDINGS[zap]} ))
    local total_actual=$(( ${ACTUAL_FINDINGS[semgrep]:-0} + ${ACTUAL_FINDINGS[trufflehog]:-0} + ${ACTUAL_FINDINGS[trivy]:-0} + ${ACTUAL_FINDINGS[snyk]:-0} + ${ACTUAL_FINDINGS[zap]:-0} ))
    local overall_coverage=$(calculate_coverage $total_actual $total_expected)
    
    # Generate JSON comparison report
    cat > "$comparison_file" << EOF
{
    "scan_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "scan_mode": "$([ "$SCAN_ONLY" = true ] && echo "scan-only" || echo "complete")",
    "summary": {
        "total_expected": $total_expected,
        "total_actual": $total_actual,
        "overall_coverage": $overall_coverage,
        "status": "$(get_status $overall_coverage)"
    },
    "tools": {
EOF

    # Add tool results
    local first=true
    for tool in semgrep trufflehog trivy snyk zap; do
        if [ "$first" = true ]; then
            first=false
        else
            echo "," >> "$comparison_file"
        fi
        
        local expected=${EXPECTED_FINDINGS[$tool]}
        local actual=${ACTUAL_FINDINGS[$tool]:-0}
        local coverage=$(calculate_coverage $actual $expected)
        local status=$(get_status $coverage)
        
        cat >> "$comparison_file" << EOF
        "$tool": {
            "expected": $expected,
            "actual": $actual,
            "coverage_percent": $coverage,
            "status": "$status",
            "scan_status": "${SCAN_STATUS[$tool]:-UNKNOWN}"
        }
EOF
    done
    
    echo "    }" >> "$comparison_file"
    echo "}" >> "$comparison_file"
    
    log "✅ Comparison report generated"
}

# Function to start security dashboard
start_dashboard() {
    log "🎯 Starting security dashboard..."
    
    # Stop any existing dashboard containers first
    docker-compose stop security-dashboard 2>/dev/null || true
    docker-compose rm -f security-dashboard 2>/dev/null || true
    sleep 2
    
    # Start dashboard container
    docker-compose --profile security up -d security-dashboard 2>/dev/null || true
    
    # Wait for dashboard to be ready
    sleep 5
    if nc -z localhost 9000 2>/dev/null; then
        log "✅ Security dashboard ready at http://localhost:9000"
        
        # Display Codespaces URL if available
        if [ -n "${CODESPACE_NAME:-}" ]; then
            log "🌐 Codespaces URL: https://${CODESPACE_NAME}-9000.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
        fi
    else
        log "⚠️ Dashboard may need a moment to start - try again in 10 seconds"
    fi
}

# Function to display final summary
display_summary() {
    echo ""
    echo "🎉 CSB DevSecOps Environment Complete!"
    echo "====================================="
    echo ""
    echo "📊 Security Scan Results:"
    printf "%-15s %-10s %-10s %-10s %-12s\n" "Tool" "Expected" "Actual" "Coverage" "Status"
    printf "%-15s %-10s %-10s %-10s %-12s\n" "----" "--------" "------" "--------" "------"
    
    for tool in semgrep trufflehog trivy snyk zap; do
        local expected=${EXPECTED_FINDINGS[$tool]}
        local actual=${ACTUAL_FINDINGS[$tool]:-0}
        local coverage=$(calculate_coverage $actual $expected)
        local status=$(get_status $coverage)
        
        printf "%-15s %-10s %-10s %-9s%% %-12s\n" "$tool" "$expected" "$actual" "$coverage" "$status"
    done
    
    if [ "$SCAN_ONLY" = false ]; then
        echo ""
        echo "🌐 Service URLs (auto-forwarded in Codespaces):"
        echo "  React App:           http://localhost:3000"
        echo "  Angular App:         http://localhost:4200"
        echo "  Django API:          http://localhost:8000"
        echo "  Flask API:           http://localhost:5000"
        echo "  Spring Boot API:     http://localhost:8080/api/health"
        echo "  .NET Core API:       http://localhost:8090"
        echo "  Node.js Express:     http://localhost:3001"
        echo "  PHP/Drupal:         http://localhost:8888"
        echo "  Adminer:            http://localhost:8081"
    fi
    
    echo "  🎯 Security Dashboard: http://localhost:9000"
    echo ""
    echo "📂 Security Reports:"
    echo "  📊 Interactive Dashboard: http://localhost:9000"
    echo "  📄 JSON Report:          security-reports/comparison/expected-vs-actual.json"
    echo "  📁 All Reports:          security-reports/"
    echo ""
    echo "💡 Commands:"
    echo "  Complete setup:          $0"
    echo "  Security scans only:     $0 --scan-only"
    echo "  Check service status:    docker-compose ps"
    echo "  View service logs:       docker-compose logs [service-name]"
    echo "  Stop all services:       docker-compose down"
    echo ""
    
    local total_expected=$(( ${EXPECTED_FINDINGS[semgrep]} + ${EXPECTED_FINDINGS[trufflehog]} + ${EXPECTED_FINDINGS[trivy]} + ${EXPECTED_FINDINGS[snyk]} + ${EXPECTED_FINDINGS[zap]} ))
    local total_actual=$(( ${ACTUAL_FINDINGS[semgrep]:-0} + ${ACTUAL_FINDINGS[trufflehog]:-0} + ${ACTUAL_FINDINGS[trivy]:-0} + ${ACTUAL_FINDINGS[snyk]:-0} + ${ACTUAL_FINDINGS[zap]:-0} ))
    local overall_coverage=$(calculate_coverage $total_actual $total_expected)
    
    if [ $overall_coverage -ge 80 ]; then
        echo "🎯 EXCELLENT: Security tools are detecting expected vulnerabilities!"
        echo "✅ Your DevSecOps pipeline is working correctly."
    elif [ $overall_coverage -ge 60 ]; then
        echo "✅ GOOD: Most security tools are working properly."
        echo "💡 Consider reviewing tools with low coverage."
    else
        echo "⚠️ WARNING: Security tool configuration may need review."
        echo "🔧 Check individual tool logs and configurations."
    fi
    
    echo ""
    echo "🎉 Environment ready for security tool evaluation!"
}

# Main execution function
main() {
    if [ "$SCAN_ONLY" = true ]; then
        log "🔒 Running security scans only..."
        echo "Mode: Security scanning only (skipping service startup)"
    else
        log "🚀 Starting complete CSB DevSecOps environment..."
        echo "Mode: Complete setup (services + scans + dashboard)"
    fi
    
    echo ""
    echo "🎯 This script will:"
    if [ "$SCAN_ONLY" = false ]; then
        echo "   1. Fix Docker permissions if needed"
        echo "   2. Setup directory structure and dashboard"
        echo "   3. Start all applications in proper order"
        echo "   4. Run comprehensive security scans"
        echo "   5. Generate expected vs actual comparison"
        echo "   6. Launch interactive security dashboard"
    else
        echo "   1. Fix Docker permissions if needed"
        echo "   2. Setup directory structure and dashboard"
        echo "   3. Run comprehensive security scans"
        echo "   4. Generate expected vs actual comparison"
        echo "   5. Launch interactive security dashboard"
    fi
    echo ""
    
    # Execute all phases
    fix_docker_permissions
    setup_environment
    start_services
    run_security_scans
    start_dashboard
    display_summary
}

# Execute main function with all arguments
main "$@"