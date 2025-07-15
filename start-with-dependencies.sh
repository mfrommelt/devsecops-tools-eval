#!/bin/bash
# Proper CSB DevSecOps Startup with Dependencies

echo "🚀 CSB DevSecOps Environment - Proper Startup Order"
echo "===================================================="

# Function to wait for service to be ready
wait_for_service() {
    local service=$1
    local port=$2
    local max_attempts=30
    local attempt=1
    
    echo "⏳ Waiting for $service to be ready on port $port..."
    
    while [ $attempt -le $max_attempts ]; do
        if docker-compose exec $service pg_isready -U postgres >/dev/null 2>&1 || \
           docker-compose exec $service mysqladmin ping -h localhost -u root -prootpassword >/dev/null 2>&1 || \
           nc -z localhost $port >/dev/null 2>&1; then
            echo "✅ $service is ready!"
            return 0
        fi
        
        echo "   Attempt $attempt/$max_attempts - $service not ready yet..."
        sleep 5
        ((attempt++))
    done
    
    echo "❌ $service failed to become ready after $((max_attempts * 5)) seconds"
    return 1
}

# Function to check PostgreSQL specifically
wait_for_postgres() {
    echo "🐘 Waiting for PostgreSQL to be ready..."
    local attempt=1
    local max_attempts=30
    
    while [ $attempt -le $max_attempts ]; do
        if docker-compose exec postgres pg_isready -U postgres >/dev/null 2>&1; then
            echo "✅ PostgreSQL is ready!"
            return 0
        fi
        echo "   Attempt $attempt/$max_attempts - PostgreSQL not ready..."
        sleep 5
        ((attempt++))
    done
    
    echo "❌ PostgreSQL failed to become ready"
    return 1
}

# Function to check MySQL specifically  
wait_for_mysql() {
    echo "🐬 Waiting for MySQL to be ready..."
    local attempt=1
    local max_attempts=30
    
    while [ $attempt -le $max_attempts ]; do
        if docker-compose exec mysql mysqladmin ping -h localhost -u root -prootpassword >/dev/null 2>&1; then
            echo "✅ MySQL is ready!"
            return 0
        fi
        echo "   Attempt $attempt/$max_attempts - MySQL not ready..."
        sleep 5
        ((attempt++))
    done
    
    echo "❌ MySQL failed to become ready"
    return 1
}

# Step 1: Start databases first
echo ""
echo "📊 Step 1: Starting Database Services"
echo "------------------------------------"
docker-compose up -d postgres mysql oracle

echo ""
echo "⏳ Waiting for databases to initialize (this may take 60-90 seconds)..."
sleep 30

# Step 2: Wait for databases to be ready
echo ""
echo "🔍 Step 2: Verifying Database Readiness"
echo "--------------------------------------"

wait_for_postgres
wait_for_mysql

echo "⏳ Waiting additional 10 seconds for Oracle..."
sleep 10

# Step 3: Start backend services that depend on databases
echo ""
echo "⚙️  Step 3: Starting Backend Applications"
echo "---------------------------------------"

echo "Starting Spring Boot API..."
docker-compose up -d spring-boot-api
sleep 10

echo "Starting Django App..."
docker-compose up -d django-app
sleep 10

echo "Starting Flask API..."
docker-compose up -d flask-api
sleep 10

echo "Starting Node.js Express..."
docker-compose up -d node-express
sleep 10

echo "Starting .NET API..."
docker-compose up -d dotnet-api
sleep 10

echo "Starting PHP/Drupal..."
docker-compose up -d php-drupal
sleep 10

# Step 4: Start frontend applications
echo ""
echo "🖥️  Step 4: Starting Frontend Applications"
echo "----------------------------------------"

echo "Starting React App..."
docker-compose up -d react-app
sleep 5

echo "Starting Angular App..."
docker-compose up -d angular-app
sleep 5

# Step 5: Start supporting services
echo ""
echo "🛠️  Step 5: Starting Supporting Services"
echo "---------------------------------------"

echo "Starting Adminer..."
docker-compose up -d adminer

# Step 6: Health check all services
echo ""
echo "🏥 Step 6: Health Check All Services"
echo "====================================="

services=(
    "postgres:5432"
    "mysql:3306" 
    "spring-boot-api:8080"
    "django-app:8000"
    "flask-api:5000"
    "node-express:3001"
    "dotnet-api:8090"
    "php-drupal:8888"
    "react-app:3000"
    "angular-app:4200"
    "adminer:8081"
)

echo "Waiting 30 seconds for all services to fully initialize..."
sleep 30

working_services=0
total_services=${#services[@]}

for service_port in "${services[@]}"; do
    service=$(echo $service_port | cut -d: -f1)
    port=$(echo $service_port | cut -d: -f2)
    
    echo -n "Testing $service (port $port)... "
    
    if curl -f -s http://localhost:$port >/dev/null 2>&1; then
        echo "✅ WORKING"
        ((working_services++))
    else
        echo "❌ NOT RESPONDING"
        echo "  Check logs: docker-compose logs $service"
    fi
done

# Step 7: Summary
echo ""
echo "📊 STARTUP SUMMARY"
echo "=================="
echo "Working Services: $working_services/$total_services"
echo ""

if [ $working_services -eq $total_services ]; then
    echo "🎉 SUCCESS! All services are running!"
    echo ""
    echo "🌐 Service URLs:"
    echo "  React App:      http://localhost:3000"
    echo "  Angular App:    http://localhost:4200"
    echo "  Django API:     http://localhost:8000"
    echo "  Flask API:      http://localhost:5000"
    echo "  Spring Boot:    http://localhost:8080/api/health"
    echo "  .NET Core API:  http://localhost:8090"
    echo "  Node.js API:    http://localhost:3001"
    echo "  PHP/Drupal:    http://localhost:8888"
    echo "  Adminer:        http://localhost:8081"
    echo ""
    echo "🔒 Ready for security testing!"
    echo "   Run: ./scripts/security/run-security-scans.sh"
else
    echo "⚠️  Some services need attention."
    echo ""
    echo "🔧 Troubleshooting commands:"
    echo "  View logs: docker-compose logs [service-name]"
    echo "  Restart service: docker-compose restart [service-name]"
    echo "  Check status: docker-compose ps"
fi

echo ""
echo "✅ Startup script completed!"