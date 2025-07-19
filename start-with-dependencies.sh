#!/bin/bash
# Codespaces-optimized startup script with integrated Docker permissions fix

echo "🚀 CSB DevSecOps Environment - Startup"
echo "==================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to fix Docker permissions and access
fix_docker_permissions() {
    print_status $BLUE "🔧 Checking and fixing Docker access..."
    
    # Check if Docker socket exists
    if [ ! -S "/var/run/docker.sock" ]; then
        print_status $RED "❌ Docker socket not found"
        return 1
    fi
    
    # Check current Docker access
    if docker info >/dev/null 2>&1; then
        print_status $GREEN "✅ Docker access is already working"
        return 0
    fi
    
    print_status $YELLOW "⚠️  Docker access needs fixing..."
    
    # Kill any failed dockerd processes we might have started
    sudo pkill -f "dockerd.*$USER" 2>/dev/null || true
    
    # Fix socket permissions
    print_status $BLUE "Fixing Docker socket permissions..."
    sudo chown root:docker /var/run/docker.sock 2>/dev/null || sudo chown root:root /var/run/docker.sock
    sudo chmod 666 /var/run/docker.sock
    
    # Add user to docker group
    sudo usermod -aG docker $USER 2>/dev/null || true
    
    # Test Docker access
    if docker info >/dev/null 2>&1; then
        print_status $GREEN "✅ Docker access fixed!"
        return 0
    elif sudo docker info >/dev/null 2>&1; then
        print_status $YELLOW "⚠️  Docker requires sudo - creating alias"
        
        # Create temporary aliases for this session
        alias docker='sudo docker'
        alias docker-compose='sudo docker-compose'
        
        # Set environment variable to track sudo requirement
        export DOCKER_NEEDS_SUDO=true
        
        print_status $GREEN "✅ Docker access working with sudo"
        return 0
    else
        print_status $RED "❌ Docker still not accessible"
        return 1
    fi
}

# Function to run docker commands (with sudo if needed)
docker_cmd() {
    if [ "$DOCKER_NEEDS_SUDO" = true ]; then
        sudo docker "$@"
    else
        docker "$@"
    fi
}

# Function to run docker-compose commands (with sudo if needed)
docker_compose_cmd() {
    if [ "$DOCKER_NEEDS_SUDO" = true ]; then
        sudo docker-compose "$@"
    else
        docker-compose "$@"
    fi
}

# Check if we're in Codespaces
if [ -n "$CODESPACE_NAME" ]; then
    print_status $BLUE "🌐 Running in GitHub Codespaces: $CODESPACE_NAME"
    CODESPACES_MODE=true
else
    print_status $BLUE "💻 Running in local development mode"
    CODESPACES_MODE=false
fi

# Step 0: Fix Docker access and permissions
echo ""
print_status $BLUE "🐳 Step 0: Docker Environment Setup"
print_status $BLUE "==================================="

# Fix docker-compose.yml version warning first
if [ -f "docker-compose.yml" ] && grep -q "^version:" docker-compose.yml; then
    print_status $BLUE "Removing obsolete version line from docker-compose.yml..."
    cp docker-compose.yml docker-compose.yml.backup
    sed -i '/^version:/d' docker-compose.yml
    print_status $GREEN "✅ Fixed docker-compose.yml"
fi

# Fix Docker permissions
if ! fix_docker_permissions; then
    print_status $RED "❌ Cannot fix Docker access. Please try:"
    echo "  1. Restart Codespace: Ctrl+Shift+P → 'Codespaces: Rebuild Container'"
    echo "  2. Or use manual commands: sudo docker-compose up -d"
    exit 1
fi

# Test docker-compose
print_status $BLUE "Testing docker-compose configuration..."
if docker_compose_cmd config >/dev/null 2>&1; then
    print_status $GREEN "✅ docker-compose is working"
elif docker compose config >/dev/null 2>&1; then
    print_status $GREEN "✅ docker compose (V2) is working"
    # Create function to use docker compose instead
    docker_compose_cmd() {
        if [ "$DOCKER_NEEDS_SUDO" = true ]; then
            sudo docker compose "$@"
        else
            docker compose "$@"
        fi
    }
else
    print_status $RED "❌ docker-compose validation failed"
    echo "Current directory: $(pwd)"
    echo "Compose file exists: $([ -f docker-compose.yml ] && echo 'Yes' || echo 'No')"
    exit 1
fi

# Function to wait for database with Docker command wrapper
wait_for_db() {
    local db_type=$1
    local service=$2
    local max_attempts=60
    local attempt=1
    
    print_status $BLUE "⏳ Waiting for $db_type to be ready..."
    
    while [ $attempt -le $max_attempts ]; do
        case $db_type in
            "PostgreSQL")
                if docker_compose_cmd exec -T $service pg_isready -U postgres >/dev/null 2>&1; then
                    print_status $GREEN "✅ $db_type is ready!"
                    return 0
                fi
                ;;
            "MySQL")
                if docker_compose_cmd exec -T $service mysqladmin ping -h localhost -u root -prootpassword >/dev/null 2>&1; then
                    print_status $GREEN "✅ $db_type is ready!"
                    return 0
                fi
                ;;
        esac
        
        if [ $((attempt % 10)) -eq 0 ]; then
            print_status $YELLOW "   Still waiting for $db_type... (${attempt}0s)"
        fi
        sleep 5
        ((attempt++))
    done
    
    print_status $RED "❌ $db_type failed to become ready after $((max_attempts * 5)) seconds"
    return 1
}

# Function to check container status with Docker command wrapper
check_container_status() {
    local service=$1
    
    if docker_compose_cmd ps $service | grep -q "Up"; then
        print_status $GREEN "✅ $service: Container is running"
        return 0
    else
        print_status $YELLOW "⚠️  $service: Container may be starting or failed"
        return 1
    fi
}

# Create Docker network
echo ""
print_status $BLUE "🌐 Setting up Docker environment..."
docker_cmd network create csb-test-network 2>/dev/null || print_status $GREEN "✅ Network already exists"

# Step 1: Start databases first
echo ""
print_status $BLUE "📊 Step 1: Starting Database Services"
print_status $BLUE "------------------------------------"

print_status $BLUE "Starting databases..."
docker_compose_cmd up -d postgres mysql oracle

# Wait for databases with longer timeouts for Codespaces
wait_for_db "PostgreSQL" "postgres"
wait_for_db "MySQL" "mysql"

# Give Oracle extra time (always slow)
print_status $BLUE "⏳ Waiting for Oracle to initialize (this takes 60-90 seconds)..."
sleep 60

# Step 2: Start backend services
echo ""
print_status $BLUE "⚙️  Step 2: Starting Backend Applications"
print_status $BLUE "---------------------------------------"

backend_services=("spring-boot-api" "django-app" "flask-api" "node-express" "dotnet-api" "php-drupal")

for service in "${backend_services[@]}"; do
    print_status $BLUE "Starting $service..."
    docker_compose_cmd up -d $service
    sleep 20
    check_container_status $service
done

# Step 3: Start frontend applications
echo ""
print_status $BLUE "🖥️  Step 3: Starting Frontend Applications"
print_status $BLUE "----------------------------------------"

frontend_services=("react-app" "angular-app")
for service in "${frontend_services[@]}"; do
    print_status $BLUE "Starting $service..."
    docker_compose_cmd up -d $service
    sleep 15
    check_container_status $service
done

# Step 4: Start supporting services
echo ""
print_status $BLUE "🛠️  Step 4: Starting Supporting Services"
print_status $BLUE "---------------------------------------"

print_status $BLUE "Starting Adminer..."
docker_compose_cmd up -d adminer

# Step 5: Final health check
echo ""
print_status $BLUE "🏥 Step 5: Service Health Check"
print_status $BLUE "==============================="

print_status $BLUE "⏳ Waiting 60 seconds for all services to stabilize..."
sleep 60

print_status $BLUE "Checking service status..."
declare -A services=(
    ["spring-boot-api"]="8080"
    ["django-app"]="8000"
    ["flask-api"]="5000"
    ["node-express"]="3001"
    ["dotnet-api"]="8090"
    ["php-drupal"]="8888"
    ["react-app"]="3000"
    ["angular-app"]="4200"
    ["adminer"]="8081"
)

working_services=0
total_services=${#services[@]}

for service in "${!services[@]}"; do
    port=${services[$service]}
    
    if check_container_status $service; then
        ((working_services++))
        
        # Try HTTP check (may not work in Codespaces due to port forwarding)
        if curl -f -s --max-time 5 http://localhost:$port >/dev/null 2>&1; then
            print_status $GREEN "   HTTP response OK on port $port"
        else
            print_status $YELLOW "   Container running (HTTP check skipped - normal in Codespaces)"
        fi
    else
        print_status $YELLOW "   Check logs: docker-compose logs $service"
    fi
done

# Step 6: Results and guidance
echo ""
print_status $BLUE "📊 STARTUP SUMMARY"
print_status $BLUE "=================="
echo "Service Status: $working_services/$total_services containers running"
echo "Docker Mode: $([ "$DOCKER_NEEDS_SUDO" = true ] && echo "sudo required" || echo "direct access")"

if [ $working_services -ge $((total_services * 70 / 100)) ]; then
    print_status $GREEN "🎉 SUCCESS! Most services are running"
    
    echo ""
    if [ "$CODESPACES_MODE" = true ]; then
        print_status $GREEN "🌐 Codespaces Service URLs:"
        echo "   Access via VS Code 'Ports' tab or forwarded URLs:"
        echo "   • React App: Port 3000"
        echo "   • Angular App: Port 4200" 
        echo "   • Django API: Port 8000"
        echo "   • Spring Boot API: Port 8080"
        echo "   • PHP/Drupal: Port 8888"
        echo "   • Adminer: Port 8081"
    else
        print_status $GREEN "🌐 Local Service URLs:"
        echo "   • React App: http://localhost:3000"
        echo "   • Angular App: http://localhost:4200"
        echo "   • Django API: http://localhost:8000"
        echo "   • Spring Boot API: http://localhost:8080"
        echo "   • PHP/Drupal: http://localhost:8888"
        echo "   • Adminer: http://localhost:8081"
    fi
    
    echo ""
    print_status $GREEN "🔒 Ready for security testing!"
    echo "   Run: ./scripts/security/run-security-scans.sh"
    
else
    print_status $YELLOW "⚠️  Some services need attention ($working_services/$total_services)"
    echo ""
    print_status $BLUE "🔧 Troubleshooting commands:"
    if [ "$DOCKER_NEEDS_SUDO" = true ]; then
        echo "   View logs: sudo docker-compose logs [service-name]"
        echo "   Restart service: sudo docker-compose restart [service-name]"
        echo "   Check status: sudo docker-compose ps"
    else
        echo "   View logs: docker-compose logs [service-name]"
        echo "   Restart service: docker-compose restart [service-name]"
        echo "   Check status: docker-compose ps"
    fi
fi

# Create service status file
cat > service-status.json << EOF
{
  "timestamp": "$(date -Iseconds)",
  "codespaces_mode": $CODESPACES_MODE,
  "codespace_name": "${CODESPACE_NAME:-local}",
  "docker_needs_sudo": $([ "$DOCKER_NEEDS_SUDO" = true ] && echo "true" || echo "false"),
  "total_services": $total_services,
  "running_services": $working_services,
  "success_rate": $(echo "scale=1; $working_services * 100 / $total_services" | bc),
  "ready_for_testing": $([ $working_services -ge $((total_services * 70 / 100)) ] && echo "true" || echo "false")
}
EOF

echo ""
print_status $GREEN "✅ Self-healing startup completed!"
print_status $BLUE "📋 Status saved to: service-status.json"

if [ "$CODESPACES_MODE" = true ]; then
    echo ""
    print_status $YELLOW "🎯 Codespaces Next Steps:"
    echo "1. 👀 Check VS Code 'Ports' tab for forwarded services"
    echo "2. 🌐 Click 'Open in Browser' icons to access applications"
    echo "3. 🔒 Run security scans: ./scripts/security/run-security-scans.sh"
fi

if [ "$DOCKER_NEEDS_SUDO" = true ]; then
    echo ""
    print_status $YELLOW "💡 Note: Docker commands require sudo in this session"
    print_status $BLUE "   For manual commands, use: sudo docker-compose [command]"
fi