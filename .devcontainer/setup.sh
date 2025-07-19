#!/bin/bash
# .devcontainer/setup.sh - Enhanced with better error handling and permissions

set -euo pipefail  # Exit on error, undefined vars, and pipe failures

echo "🚀 Setting up CSB DevSecOps Test Environment..."
echo "=============================================="

# Function to log with timestamp
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Function to retry commands with exponential backoff
retry_with_backoff() {
    local max_attempts=3
    local timeout=1
    local attempt=1
    local cmd="$@"
    
    while [[ $attempt -le $max_attempts ]]; do
        log "Attempt $attempt/$max_attempts: $cmd"
        if timeout 300 bash -c "$cmd"; then
            return 0
        else
            if [[ $attempt -eq $max_attempts ]]; then
                log "❌ Command failed after $max_attempts attempts: $cmd"
                return 1
            fi
            log "Command failed. Retrying in ${timeout} seconds..."
            sleep $timeout
            timeout=$((timeout * 2))
            attempt=$((attempt + 1))
        fi
    done
}

# Ensure we have basic permissions for scripts
log "🔧 Setting up permissions..."
find . -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

# Update system packages with retries
log "📦 Updating system packages..."
retry_with_backoff "sudo apt-get update -qq" || log "⚠️ Package update failed, continuing..."

# Install essential tools first
log "🔧 Installing essential tools..."
retry_with_backoff "sudo apt-get install -y curl wget git build-essential" || log "⚠️ Some tools may not be available"

# Install security tools with better error handling
log "🔒 Installing security scanning tools..."

# Install TruffleHog
log "Installing TruffleHog..."
if retry_with_backoff "curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sh -s -- -b /usr/local/bin"; then
    log "✅ TruffleHog installed successfully"
else
    log "⚠️ TruffleHog installation failed - will use Docker version"
fi

# Install Semgrep with pip timeout settings
log "Installing Semgrep..."
if retry_with_backoff "pip3 install --timeout=120 --retries=3 semgrep"; then
    log "✅ Semgrep installed successfully"
else
    log "⚠️ Semgrep installation failed - will use Docker version"
fi

# Install Snyk with npm timeout settings
log "Installing Snyk..."
if retry_with_backoff "npm install -g snyk --timeout=120000"; then
    log "✅ Snyk installed successfully"
else
    log "⚠️ Snyk installation failed - will use Docker version"
fi

# Install additional security tools (non-critical)
log "Installing additional security tools..."
pip3 install --timeout=60 --retries=2 bandit safety 2>/dev/null || log "⚠️ Some Python security tools not installed"
npm install -g audit-ci eslint-plugin-security retire --timeout=60000 2>/dev/null || log "⚠️ Some Node security tools not installed"

# Install Terraform tools if available
if curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add - 2>/dev/null; then
    sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" 2>/dev/null || true
    sudo apt-get update -qq 2>/dev/null || true
    sudo apt-get install -y terraform 2>/dev/null || log "⚠️ Terraform not installed"
fi

# Install pre-commit
log "Installing pre-commit..."
pip3 install --timeout=60 --retries=2 pre-commit 2>/dev/null || log "⚠️ Pre-commit not installed"

# Create environment configuration
log "🔧 Setting up environment configuration..."
cat > .env << 'EOF'
# CSB DevSecOps Test Environment Configuration

# Database Configuration
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_MULTIPLE_DATABASES=csbdb,flaskdb,springdb,dotnetdb,nodedb,drupaldb

MYSQL_ROOT_PASSWORD=rootpassword
MYSQL_DATABASE=drupal
MYSQL_USER=drupal
MYSQL_PASSWORD=drupal

# Application Configuration
NODE_ENV=development
FLASK_ENV=development
DJANGO_SETTINGS_MODULE=csb_project.settings
ASPNETCORE_ENVIRONMENT=Development
SPRING_PROFILES_ACTIVE=development

# Security Tool Configuration
# SEMGREP_APP_TOKEN=
# SNYK_TOKEN=
EOF

# Create Docker network
log "🌐 Setting up Docker network..."
docker network create csb-test-network 2>/dev/null || log "✅ Network already exists"

# Create directory structure
log "📁 Creating directory structure..."
mkdir -p security-reports/{general,dataweave,drupal,anypoint,mulesoft,compliance,dashboard}
mkdir -p scripts/security 2>/dev/null || true

# Make all shell scripts executable
log "🔧 Making scripts executable..."
find . -name "*.sh" -type f -exec chmod +x {} \; 2>/dev/null || true

# Pre-pull essential Docker images in background
log "📦 Pre-pulling essential Docker images..."
{
    docker pull postgres:13 2>/dev/null || true
    docker pull mysql:8.0 2>/dev/null || true
    docker pull nginx:alpine 2>/dev/null || true
} &

# Create a simple verification script if it doesn't exist
if [ ! -f "verify-setup.sh" ]; then
    log "📝 Creating verification script..."
    cat > verify-setup.sh << 'VERIFY_EOF'
#!/bin/bash
echo "🔍 Quick Setup Verification"
echo "=========================="
echo "✅ Environment file: $([ -f .env ] && echo "Created" || echo "Missing")"
echo "✅ Docker: $(docker --version 2>/dev/null || echo "Not available")"
echo "✅ Node.js: $(node --version 2>/dev/null || echo "Not available")"
echo "✅ Python: $(python3 --version 2>/dev/null || echo "Not available")"
echo "✅ Semgrep: $(semgrep --version 2>/dev/null || echo "Not available")"
echo ""
echo "🚀 Next steps:"
echo "  1. Run: ./start-with-dependencies.sh"
echo "  2. Run: ./scripts/security/run-security-scans.sh"
VERIFY_EOF
    chmod +x verify-setup.sh
fi

# Wait for background Docker pulls to complete
wait

log "✅ CSB DevSecOps Test Environment Setup Complete!"
log ""
log "🎯 Next Steps:"
log "  1. Run: ./verify-setup.sh"
log "  2. Run: ./start-with-dependencies.sh"
log "  3. Run: ./scripts/security/run-security-scans.sh"
log ""
log "🌐 Setup completed successfully with graceful error handling"