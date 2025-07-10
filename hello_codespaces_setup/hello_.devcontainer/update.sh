#!/bin/bash

# .devcontainer/update.sh
# Update script for CSB DevSecOps Test Environment

set -e

echo "🔄 Updating CSB DevSecOps Test Environment..."

# Update system packages
sudo apt-get update && sudo apt-get upgrade -y

# Update Python packages
echo "Updating Python packages..."
pip3 install --upgrade pip
pip3 install --upgrade semgrep bandit safety checkov pre-commit

# Update Node.js packages  
echo "Updating Node.js packages..."
npm update -g snyk audit-ci retire

# Update Docker images
echo "Updating Docker images..."
docker-compose pull

# Update pre-commit hooks
echo "Updating pre-commit hooks..."
pre-commit autoupdate

echo "✅ Update complete!"