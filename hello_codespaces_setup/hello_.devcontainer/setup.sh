#!/bin/bash
# .devcontainer/setup.sh

set -e

echo "🚀 Setting up CSB DevSecOps Test Environment with MuleSoft and Drupal..."

# Update system packages
sudo apt-get update

# Install security tools
echo "🔧 Installing security scanning tools..."

# Install TruffleHog
echo "Installing TruffleHog..."
curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sh -s -- -b /usr/local/bin

# Install Semgrep
echo "Installing Semgrep..."
pip3 install semgrep

# Install Snyk
echo "Installing Snyk..."
npm install -g snyk

# Install MuleSoft CLI
echo "📦 Installing MuleSoft tools..."
npm install -g mule-cli
npm install -g anypoint-cli

# Install Drupal security tools
echo "🌐 Installing Drupal security tools..."
composer global require drupal/coder
composer global require friendsofphp/php-cs-fixer
composer global require phpmd/phpmd
composer global require squizlabs/php_codesniffer

# Install Drush globally
composer global require drush/drush

# Add Composer global bin to PATH
echo 'export PATH="$HOME/.composer/vendor/bin:$PATH"' >> ~/.bashrc

# Install additional security tools
echo "Installing additional security tools..."
pip3 install bandit safety
npm install -g audit-ci eslint-plugin-security retire

# Install Terraform and related tools
echo "Installing Terraform tools..."
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform

# Install tfsec
curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash
sudo mv tfsec /usr/local/bin/

# Install Checkov
pip3 install checkov

# Install pre-commit
echo "Installing pre-commit..."
pip3 install pre-commit

# Setup pre-commit hooks
echo "Setting up pre-commit hooks..."
pre-commit install

# Create enhanced environment configuration
echo "🔧 Setting up enhanced environment configuration..."

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

# Oracle Configuration
ORACLE_PWD=oracle_password_123

# Application Configuration
NODE_ENV=development
FLASK_ENV=development
DJANGO_SETTINGS_MODULE=csb_project.settings
ASPNETCORE_ENVIRONMENT=Development
SPRING_PROFILES_ACTIVE=development

# MuleSoft Configuration
MULE_HOME=/opt/mule
MULE_ENV=development
ANYPOINT_ENV=Sandbox

# Drupal Configuration
DRUPAL_ENV=development
DRUPAL_DATABASE_URL=mysql://drupal:drupal@mysql:3306/drupal

# Security Tool Configuration (will be set from GitHub secrets)
# SEMGREP_APP_TOKEN=
# SNYK_TOKEN=
# ANYPOINT_USERNAME=
# ANYPOINT_PASSWORD=
EOF

# Make scripts executable
echo "🔧 Making scripts executable..."
chmod +x scripts/setup/*.sh
chmod +x scripts/security/*.sh
chmod +x scripts/deployment/*.sh
chmod +x scripts/mulesoft/*.sh

# Create enhanced security reports directory structure
mkdir -p security-reports/{dataweave,drupal,anypoint,mulesoft}

# Create MuleSoft-specific directories
mkdir -p backend/java-mulesoft/src/main/resources/dataweave/{transformations,mappings,functions}
mkdir -p backend/java-mulesoft/anypoint-cli/{deploy-config,api-specs,policies}

# Create Drupal-specific directories
mkdir -p backend/php-drupal/web/{modules/custom,themes/custom}
mkdir -p backend/php-drupal/config/{sync,staging}
mkdir -p backend/php-drupal/tests/{security,functional}

# Enhanced VS Code workspace configuration
echo "🔧 Configuring enhanced VS Code settings..."

mkdir -p .vscode
cat > .vscode/tasks.json << 'EOF'
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Start All Services",
            "type": "shell",
            "command": "docker-compose up -d",
            "group": "build",
            "presentation": {
                "reveal": "always",
                "panel": "new"
            }
        },
        {
            "label": "Start Drupal Only",
            "type": "shell",
            "command": "docker-compose -f docker-compose.drupal.yml up -d",
            "group": "build"
        },
        {
            "label": "Start MuleSoft Only", 
            "type": "shell",
            "command": "docker-compose -f docker-compose.mulesoft.yml up -d",
            "group": "build"
        },
        {
            "label": "Run Security Scans",
            "type": "shell", 
            "command": "./scripts/security/run-security-scans.sh",
            "group": "test",
            "presentation": {
                "reveal": "always",
                "panel": "new"
            }
        },
        {
            "label": "Run DataWeave Security Scan",
            "type": "shell",
            "command": "./scripts/security/dataweave-security-scan.sh",
            "group": "test"
        },
        {
            "label": "Run Drupal Security Scan",
            "type": "shell",
            "command": "./scripts/security/drupal-security-scan.sh", 
            "group": "test"
        }
    ]
}
EOF

# Display enhanced setup completion information
echo ""
echo "✅ Enhanced CSB DevSecOps Test Environment Setup Complete!"
echo ""
echo "🔧 Installed Security Tools:"
echo "  ✓ TruffleHog: $(trufflehog --version 2>/dev/null || echo 'installed')"
echo "  ✓ Semgrep: $(semgrep --version)"
echo "  ✓ Snyk: $(snyk --version)"
echo "  ✓ tfsec: $(tfsec --version)"
echo "  ✓ Checkov: $(checkov --version)"
echo "  ✓ Docker: $(docker --version)"
echo "  ✓ Docker Compose: $(docker-compose --version)"
echo ""
echo "🌐 MuleSoft Tools:"
echo "  ✓ MuleSoft CLI: $(mule --version 2>/dev/null || echo 'installed')"
echo "  ✓ Anypoint CLI: $(anypoint-cli --version 2>/dev/null || echo 'installed')"
echo ""
echo "🍃 Drupal Tools:"
echo "  ✓ Drush: $(drush --version 2>/dev/null || echo 'installed')"
echo "  ✓ PHP CodeSniffer: $(phpcs --version 2>/dev/null || echo 'installed')"
echo "  ✓ PHPMD: $(phpmd --version 2>/dev/null || echo 'installed')"
echo ""
echo "🚀 Next Steps:"
echo "  1. Run: docker-compose up -d"
echo "  2. Wait 60 seconds for services to start"
echo "  3. Run: ./scripts/security/run-security-scans.sh"
echo "  4. Run: ./scripts/security/dataweave-security-scan.sh"
echo "  5. Run: ./scripts/security/drupal-security-scan.sh"
echo "  6. View results in: security-reports/"
echo ""
echo "🌐 Service URLs (will be auto-forwarded):"
echo "  - React App:      http://localhost:3000"
echo "  - Angular App:    http://localhost:4200"
echo "  - Django API:     http://localhost:8000"
echo "  - Spring Boot:    http://localhost:8080"
echo "  - MuleSoft:       http://localhost:8082"
echo "  - Drupal:         http://localhost:8888"
echo "  - Flask API:      http://localhost:5000"
echo "  - .NET Core API:  http://localhost:8090"
echo "  - Node.js API:    http://localhost:3001"
echo "  - Adminer:        http://localhost:8081"
echo ""
echo "🔒 Security Testing Ready with Enhanced Coverage!"
echo "   📊 DataWeave transformations with banking vulnerabilities"
echo "   🌐 Drupal custom modules with intentional security flaws"
echo "   🔍 Comprehensive security scanning for all technologies"
echo ""