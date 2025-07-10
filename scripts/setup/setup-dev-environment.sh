#!/bin/bash
# scripts/setup/setup-dev-environment.sh

echo "🚀 Setting up CSB DevSecOps Test Environment"

# Check prerequisites
check_prerequisites() {
    echo "Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker is required but not installed"
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        echo "❌ Docker Compose is required but not installed"
        exit 1
    fi
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        echo "❌ Node.js is required but not installed"
        exit 1
    fi
    
    # Check Python
    if ! command -v python3 &> /dev/null; then
        echo "❌ Python 3 is required but not installed"
        exit 1
    fi
    
    echo "✅ Prerequisites check passed"
}

# Install security tools
install_security_tools() {
    echo "📦 Installing security tools..."
    
    # Install pre-commit
    pip3 install pre-commit
    
    # Install TruffleHog
    if ! command -v trufflehog &> /dev/null; then
        curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sh -s -- -b /usr/local/bin
    fi
    
    # Install Semgrep
    pip3 install semgrep
    
    # Install additional tools if not present
    if ! command -v trivy &> /dev/null; then
        echo "Consider installing Trivy for container scanning"
    fi
    
    if ! command -v tfsec &> /dev/null; then
        echo "Consider installing tfsec for Terraform scanning"
    fi
    
    echo "✅ Security tools installation complete"
}

# Setup pre-commit hooks
setup_precommit() {
    echo "🔧 Setting up pre-commit hooks..."
    pre-commit install
    echo "✅ Pre-commit hooks installed"
}

# Setup environment files
setup_environment() {
    echo "🔧 Setting up environment configuration..."
    
    # Create .env file for local development
    cat > .env << EOF
# CSB DevSecOps Test Environment Configuration

# Database Configuration
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_MULTIPLE_DATABASES=csbdb,flaskdb,springdb,dotnetdb,nodedb

MYSQL_ROOT_PASSWORD=rootpassword
MYSQL_DATABASE=drupal
MYSQL_USER=drupal
MYSQL_PASSWORD=drupal

# Oracle Configuration
ORACLE_PWD=oracle_password_123

# Application Configuration
NODE_ENV=development
FLASK_ENV=development
DJANGO_SETTINGS_MODULE=csb_project.settings
ASPNETCORE_ENVIRONMENT=Development
SPRING_PROFILES_ACTIVE=development

# Security Tool Configuration (set these in your GitHub repository secrets)
# SEMGREP_APP_TOKEN=your_semgrep_token
# SNYK_TOKEN=your_snyk_token
# GITHUB_TOKEN=your_github_token
EOF
    
    echo "✅ Environment configuration created"
}

# Build and start services
start_services() {
    echo "🚀 Building and starting all services..."
    
    # Build all services
    docker-compose build
    
    # Start services
    docker-compose up -d
    
    echo "⏳ Waiting for services to be ready..."
    sleep 60
    
    # Health check
    echo "🔍 Performing health checks..."
    
    services=(
        "http://localhost:3000"      # React
        "http://localhost:4200"      # Angular  
        "http://localhost:8000"      # Django
        "http://localhost:5000"      # Flask
        "http://localhost:8080"      # Spring Boot
        "http://localhost:8090"      # .NET
        "http://localhost:3001"      # Node.js
        "http://localhost:8888"      # PHP/Drupal
    )
    
    for service in "${services[@]}"; do
        if curl -f "$service" &>/dev/null; then
            echo "✅ $service is healthy"
        else
            echo "⚠️  $service is not responding"
        fi
    done
    
    echo "🎉 Environment setup complete!"
    echo ""
    echo "📋 Service URLs:"
    echo "  React App:      http://localhost:3000"
    echo "  Angular App:    http://localhost:4200"
    echo "  Django API:     http://localhost:8000"
    echo "  Flask API:      http://localhost:5000"
    echo "  Spring Boot:    http://localhost:8080"
    echo "  .NET Core API:  http://localhost:8090"
    echo "  Node.js API:    http://localhost:3001"
    echo "  PHP/Drupal:     http://localhost:8888"
    echo "  Adminer:        http://localhost:8081"
    echo ""
    echo "🔒 Run security scans with: ./scripts/security/run-security-scans.sh"
}

# Main execution
main() {
    echo "🎯 CSB DevSecOps Test Environment Setup"
    echo "========================================"
    
    check_prerequisites
    install_security_tools
    setup_precommit
    setup_environment
    start_services
    
    echo ""
    echo "🎉 Setup complete! Your CSB DevSecOps test environment is ready."
    echo "💡 Next steps:"
    echo "   1. Configure your GitHub repository secrets (SEMGREP_APP_TOKEN, SNYK_TOKEN)"
    echo "   2. Push code to trigger the CI/CD pipeline"
    echo "   3. Review security findings in GitHub Security tab"
    echo "   4. Run manual security scans with: ./scripts/security/run-security-scans.sh"
}

main "$@"