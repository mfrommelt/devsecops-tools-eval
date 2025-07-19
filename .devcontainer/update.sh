#!/bin/bash
# .devcontainer/update.sh - Simple update script for CSB DevSecOps environment

echo "🔄 CSB DevSecOps Environment Update"
echo "==================================="

# Ensure git safety
git config --global --add safe.directory ${PWD}

# Update package lists if running as root or with sudo access
if [ "$EUID" -eq 0 ] || sudo -n true 2>/dev/null; then
    echo "📦 Updating system packages..."
    sudo apt-get update -qq 2>/dev/null || echo "⚠️  Package update skipped"
fi

# Ensure Docker service is available
if command -v docker >/dev/null 2>&1; then
    echo "🐳 Docker is available"
else
    echo "⚠️  Docker not yet available - will be set up by devcontainer features"
fi

# Check for key tools and suggest setup if missing
echo "🔍 Checking development tools..."
missing_tools=()

if ! command -v node >/dev/null 2>&1; then missing_tools+=("Node.js"); fi
if ! command -v python3 >/dev/null 2>&1; then missing_tools+=("Python"); fi
if ! command -v java >/dev/null 2>&1; then missing_tools+=("Java"); fi

if [ ${#missing_tools[@]} -gt 0 ]; then
    echo "⚠️  Some tools not yet available: ${missing_tools[*]}"
    echo "   These will be installed by devcontainer features"
else
    echo "✅ Core development tools are available"
fi

echo ""
echo "✅ Update check complete!"
echo "💡 After container startup, run './verify-setup.sh' for comprehensive verification"