#!/bin/bash
# CSB DevSecOps Container Recovery Script

echo "🔧 CSB DevSecOps Environment Recovery"
echo "====================================="

# Function to check container status
check_container_status() {
    local service=$1
    local container_name="csb-devsecops-test-${service}-1"
    
    if docker ps | grep -q "$container_name"; then
        echo "✅ $service: Running"
        return 0
    elif docker ps -a | grep -q "$container_name.*Exited"; then
        echo "❌ $service: Failed (checking logs...)"
        echo "   Last 5 log lines:"
        docker logs --tail 5 "$container_name" 2>&1 | sed 's/^/     /'
        return 1
    else
        echo "⚠️  $service: Not found"
        return 1
    fi
}

# Step 1: Check current status
echo ""
echo "📊 Current Container Status:"
echo "----------------------------"
services=("postgres" "mysql" "spring-boot-api" "react-app" "angular-app" "django-app" "flask-api" "node-express" "php-drupal" "dotnet-api")

for service in "${services[@]}"; do
    check_container_status "$service"
done

# Step 2: Fix PostgreSQL first (critical dependency)
echo ""
echo "🗄️  Step 1: Fixing PostgreSQL..."
echo "--------------------------------"

if ! docker ps | grep -q "csb-devsecops-test-postgres-1"; then
    echo "PostgreSQL is down. Attempting restart..."
    docker-compose restart postgres
    echo "Waiting for PostgreSQL to start..."
    sleep 10
    
    if docker ps | grep -q "csb-devsecops-test-postgres-1"; then
        echo "✅ PostgreSQL restarted successfully"
    else
        echo "❌ PostgreSQL restart failed. Checking logs:"
        docker-compose logs postgres | tail -10
        echo ""
        echo "💡 Common PostgreSQL fixes:"
        echo "   - Check if port 5432 is already in use: lsof -i :5432"
        echo "   - Clear PostgreSQL data: docker volume rm csb-devsecops-test_postgres_data"
        echo "   - Restart with fresh volume: docker-compose down && docker-compose up -d postgres"
    fi
fi

# Step 3: Fix Spring Boot API (Java compilation issue)
echo ""
echo "☕ Step 2: Fixing Spring Boot API..."
echo "-----------------------------------"

if [ -f "backend/java-springboot/src/main/java/com/api/SecurityTestController.java" ]; then
    echo "Checking for Java syntax errors..."
    
    # Check for common issues
    if grep -q "@@PostMapping" backend/java-springboot/src/main/java/com/api/SecurityTestController.java; then
        echo "❌ Found double @ symbol issue"
        echo "💡 Fix needed: Change @@PostMapping to @PostMapping"
    fi
    
    # Check for missing braces
    open_braces=$(grep -o '{' backend/java-springboot/src/main/java/com/api/SecurityTestController.java | wc -l)
    close_braces=$(grep -o '}' backend/java-springboot/src/main/java/com/api/SecurityTestController.java | wc -l)
    
    if [ "$open_braces" -ne "$close_braces" ]; then
        echo "❌ Mismatched braces: $open_braces opening, $close_braces closing"
        echo "💡 Fix needed: Add missing closing braces"
    fi
    
    echo ""
    echo "🔨 Rebuilding Spring Boot container..."
    docker-compose build spring-boot-api
    docker-compose up -d spring-boot-api
else
    echo "❌ SecurityTestController.java not found in expected location"
    echo "💡 Checking alternative locations..."
    find backend/java-springboot/src -name "SecurityTestController.java" -type f
fi

# Step 4: Fix Frontend Applications
echo ""
echo "🖥️  Step 3: Fixing Frontend Applications..."
echo "-------------------------------------------"

# React App
echo "Fixing React App..."
if [ -f "frontend/react-app/package.json" ]; then
    echo "React package.json exists, rebuilding..."
    docker-compose build react-app
    docker-compose up -d react-app
    sleep 5
    check_container_status "react-app"
else
    echo "❌ React package.json not found"
fi

# Angular App  
echo "Fixing Angular App..."
if [ -f "frontend/angular-app/package.json" ]; then
    echo "Angular package.json exists, rebuilding..."
    docker-compose build angular-app
    docker-compose up -d angular-app
    sleep 5
    check_container_status "angular-app"
else
    echo "❌ Angular package.json not found"
fi

# Step 5: Fix Backend APIs
echo ""
echo "⚙️  Step 4: Fixing Backend APIs..."
echo "---------------------------------"

# Flask API
echo "Fixing Flask API..."
if [ -f "backend/python-flask/app.py" ]; then
    docker-compose build flask-api
    docker-compose up -d flask-api
    sleep 5
    check_container_status "flask-api"
fi

# Django App
echo "Fixing Django App..."
if [ -f "backend/python-django/manage.py" ]; then
    docker-compose build django-app
    docker-compose up -d django-app
    sleep 5
    check_container_status "django-app"
fi

# Step 6: Final Status Check
echo ""
echo "🎯 Final Status Check:"
echo "---------------------"

all_healthy=true
for service in "${services[@]}"; do
    if ! check_container_status "$service"; then
        all_healthy=false
    fi
done

if [ "$all_healthy" = true ]; then
    echo ""
    echo "🎉 SUCCESS: All services are running!"
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
    echo "🔒 Next Steps:"
    echo "  1. Test services: curl http://localhost:8080/api/health"
    echo "  2. Run security scans: ./scripts/security/run-security-scans.sh"
    echo "  3. Access applications through the URLs above"
else
    echo ""
    echo "⚠️  Some services are still failing. Check the logs above for specific errors."
    echo ""
    echo "🛠️  Additional troubleshooting commands:"
    echo "  - View all logs: docker-compose logs"
    echo "  - Restart all: docker-compose restart"
    echo "  - Clean rebuild: docker-compose down && docker-compose up --build -d"
    echo "  - Check ports: netstat -tulpn | grep -E ':(3000|4200|8000|5000|8080|8090|3001|8888)'"
fi

echo ""
echo "📞 Need help? Check the troubleshooting section in README.md"