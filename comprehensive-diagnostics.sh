#!/bin/bash
# Comprehensive CSB DevSecOps Diagnostics

echo "🔍 CSB DevSecOps Environment Diagnostics"
echo "========================================"

# Check Docker and system resources
echo ""
echo "🐳 Docker System Information:"
echo "-----------------------------"
docker --version
docker-compose --version
echo "Docker daemon status: $(systemctl is-active docker 2>/dev/null || echo 'unknown')"

# Check system resources
echo ""
echo "💾 System Resources:"
echo "-------------------"
echo "Available memory:"
free -h
echo ""
echo "Disk space:"
df -h / | head -2

# Check container status
echo ""
echo "📦 Container Status:"
echo "------------------"
docker-compose ps

# Check port conflicts
echo ""
echo "🔌 Port Conflict Analysis:"
echo "-------------------------"
ports=(3000 3001 4200 5000 5432 3306 8000 8080 8081 8090 8888 1521)

for port in "${ports[@]}"; do
    echo -n "Port $port: "
    if lsof -i :$port >/dev/null 2>&1; then
        process=$(lsof -i :$port | tail -1 | awk '{print $1 " (PID " $2 ")"}')
        echo "❌ IN USE by $process"
    else
        echo "✅ Available"
    fi
done

# Check Docker networks
echo ""
echo "🌐 Docker Networks:"
echo "------------------"
docker network ls
echo ""
echo "CSB test network details:"
docker network inspect csb-devsecops-test_csb-test-network 2>/dev/null || echo "Network not found"

# Check database logs specifically
echo ""
echo "📊 Database Container Logs:"
echo "--------------------------"
echo "PostgreSQL Status:"
if docker-compose ps postgres | grep -q "Up"; then
    echo "✅ PostgreSQL container is Up"
else
    echo "❌ PostgreSQL container issue"
fi

echo ""
echo "PostgreSQL last 10 log lines:"
docker-compose logs --tail 10 postgres 2>/dev/null || echo "No logs available"

echo ""
echo "MySQL Status:"
if docker-compose ps mysql | grep -q "Up"; then
    echo "✅ MySQL container is Up"  
else
    echo "❌ MySQL container issue"
fi

echo ""
echo "MySQL last 10 log lines:"
docker-compose logs --tail 10 mysql 2>/dev/null || echo "No logs available"

# Check application logs
echo ""
echo "🔧 Application Status Check:"
echo "----------------------------"

apps=("spring-boot-api" "django-app" "flask-api" "node-express" "dotnet-api" "react-app" "angular-app")

for app in "${apps[@]}"; do
    echo ""
    echo "$app status:"
    if docker-compose ps $app | grep -q "Up"; then
        echo "✅ Container is Up"
    else
        echo "❌ Container issue - checking logs:"
        docker-compose logs --tail 5 $app 2>/dev/null || echo "No logs available"
    fi
done

# Check Docker volume issues
echo ""
echo "💾 Docker Volume Status:"
echo "-----------------------"
docker volume ls | grep csb

# Check if containers are actually running
echo ""
echo "🏃‍♂️ Running Containers:"
echo "----------------------"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep csb

# Network connectivity test from inside containers
echo ""
echo "🌐 Internal Network Connectivity:"
echo "--------------------------------"
echo "Testing PostgreSQL connection from inside Spring Boot container:"
docker-compose exec spring-boot-api nc -z postgres 5432 2>/dev/null && echo "✅ Spring Boot can reach PostgreSQL" || echo "❌ Spring Boot cannot reach PostgreSQL"

echo ""
echo "Testing MySQL connection from inside Drupal container:"
docker-compose exec php-drupal nc -z mysql 3306 2>/dev/null && echo "✅ Drupal can reach MySQL" || echo "❌ Drupal cannot reach MySQL"

# Check for common issues
echo ""
echo "🚨 Common Issues Check:"
echo "----------------------"

# Check if ports are bound to host
echo "Checking if services are binding to host ports:"
netstat -tulpn 2>/dev/null | grep -E ":(3000|3001|4200|5000|5432|3306|8000|8080|8090|8888)" || echo "No services found binding to expected ports"

# Check Docker daemon logs for errors
echo ""
echo "Recent Docker daemon issues:"
journalctl -u docker.service --since "10 minutes ago" --no-pager | tail -5 2>/dev/null || echo "Cannot access Docker daemon logs"

# Summary and recommendations
echo ""
echo "🎯 DIAGNOSTIC SUMMARY & RECOMMENDATIONS:"
echo "========================================"

# Check if this is a resource issue
total_containers=$(docker-compose ps | wc -l)
if [ $total_containers -gt 15 ]; then
    echo "⚠️  Large number of containers detected ($total_containers)"
    echo "   Consider starting services in smaller groups"
fi

# Check if this is a port conflict issue
conflicted_ports=0
for port in "${ports[@]}"; do
    if lsof -i :$port >/dev/null 2>&1; then
        ((conflicted_ports++))
    fi
done

if [ $conflicted_ports -gt 0 ]; then
    echo "❌ Port conflicts detected on $conflicted_ports ports"
    echo "   Solution: Stop conflicting services or change ports"
fi

echo ""
echo "📋 NEXT STEPS:"
echo "1. Review the port conflicts above"
echo "2. Check individual service logs: docker-compose logs [service-name]"
echo "3. Try starting services individually: docker-compose up -d postgres"
echo "4. Check system resources and free up memory if needed"

echo ""
echo "🔧 QUICK FIXES TO TRY:"
echo "1. Stop all and restart: docker-compose down && docker-compose up -d"
echo "2. Clean restart: docker system prune -f && docker-compose up -d"
echo "3. Start only databases first: docker-compose up -d postgres mysql"