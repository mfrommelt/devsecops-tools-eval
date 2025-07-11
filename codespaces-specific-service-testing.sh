#!/bin/bash
# Codespaces-specific Service Testing

echo "🌐 GitHub Codespaces Service Testing"
echo "===================================="

# Get the Codespaces URL base
if [ -n "$CODESPACE_NAME" ]; then
    CODESPACE_URL="https://${CODESPACE_NAME}-8080.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
    echo "✅ Running in GitHub Codespaces: $CODESPACE_NAME"
    echo "🔗 Base URL pattern: https://${CODESPACE_NAME}-[PORT].${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
else
    echo "⚠️  Not running in Codespaces - using localhost"
fi

echo ""
echo "🔍 Method 1: Container-to-Container Testing"
echo "============================================"

echo "Testing internal container connectivity..."

# Test database connections from inside application containers
echo ""
echo "📊 Database Connectivity Tests:"
echo "-------------------------------"

echo -n "PostgreSQL from Spring Boot container: "
if docker-compose exec spring-boot-api timeout 5 bash -c 'echo > /dev/tcp/postgres/5432' 2>/dev/null; then
    echo "✅ Connected"
else
    echo "❌ Failed"
fi

echo -n "MySQL from Drupal container: "
if docker-compose exec php-drupal timeout 5 bash -c 'echo > /dev/tcp/mysql/3306' 2>/dev/null; then
    echo "✅ Connected"
else
    echo "❌ Failed"
fi

echo ""
echo "🌐 Application Health Tests (Container Internal):"
echo "------------------------------------------------"

# Test applications from inside their own containers
echo -n "Spring Boot internal health: "
if docker-compose exec spring-boot-api timeout 5 bash -c 'echo > /dev/tcp/localhost/8080' 2>/dev/null; then
    echo "✅ Port listening"
else
    echo "❌ Not listening"
fi

echo -n "Flask internal health: "
if docker-compose exec flask-api timeout 5 bash -c 'echo > /dev/tcp/localhost/5000' 2>/dev/null; then
    echo "✅ Port listening"
else
    echo "❌ Not listening"
fi

echo -n "Node Express internal health: "
if docker-compose exec node-express timeout 5 bash -c 'echo > /dev/tcp/localhost/3000' 2>/dev/null; then
    echo "✅ Port listening"
else
    echo "❌ Not listening"
fi

echo ""
echo "🔍 Method 2: Host Port Testing"
echo "=============================="

echo "Testing if ports are reachable from the Codespaces host..."

ports=(8080 5000 3001 8090 8888 3000 4200 8000 8081)
services=("Spring Boot API" "Flask API" "Node Express" ".NET API" "PHP/Drupal" "React App" "Angular App" "Django App" "Adminer")

for i in "${!ports[@]}"; do
    port=${ports[$i]}
    service=${services[$i]}
    
    echo -n "Testing $service (port $port): "
    
    # Use different testing methods for Codespaces
    if timeout 3 bash -c "echo > /dev/tcp/127.0.0.1/$port" 2>/dev/null; then
        echo "✅ Reachable on 127.0.0.1:$port"
    elif timeout 3 bash -c "echo > /dev/tcp/localhost/$port" 2>/dev/null; then
        echo "✅ Reachable on localhost:$port"
    else
        echo "❌ Not reachable"
    fi
done

echo ""
echo "🔍 Method 3: HTTP Testing with wget"
echo "==================================="

echo "Testing HTTP responses (more reliable than curl in containers)..."

http_services=(
    "Spring Boot:127.0.0.1:8080/api/health"
    "Flask:127.0.0.1:5000"
    "Node Express:127.0.0.1:3001"
    ".NET API:127.0.0.1:8090"
    "PHP/Drupal:127.0.0.1:8888"
    "Adminer:127.0.0.1:8081"
)

for service_url in "${http_services[@]}"; do
    service=$(echo $service_url | cut -d: -f1)
    url=$(echo $service_url | cut -d: -f2-3)
    
    echo -n "HTTP test $service: "
    
    if timeout 5 wget -q --spider "http://$url" 2>/dev/null; then
        echo "✅ HTTP OK"
    else
        echo "❌ HTTP Failed"
    fi
done

echo ""
echo "🌐 Codespaces URL Information"
echo "============================"

if [ -n "$CODESPACE_NAME" ]; then
    echo "Your Codespaces forwarded URLs should be:"
    echo "  Spring Boot API: https://${CODESPACE_NAME}-8080.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}/api/health"
    echo "  Flask API:       https://${CODESPACE_NAME}-5000.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}/"
    echo "  Node Express:    https://${CODESPACE_NAME}-3001.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}/"
    echo "  .NET API:        https://${CODESPACE_NAME}-8090.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}/"
    echo "  PHP/Drupal:     https://${CODESPACE_NAME}-8888.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}/"
    echo "  React App:       https://${CODESPACE_NAME}-3000.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}/"
    echo "  Angular App:     https://${CODESPACE_NAME}-4200.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}/"
    echo "  Django App:      https://${CODESPACE_NAME}-8000.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}/"
    echo "  Adminer:         https://${CODESPACE_NAME}-8081.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}/"
    echo ""
    echo "🔗 These URLs should work in your browser!"
else
    echo "Not in Codespaces - use localhost URLs"
fi

echo ""
echo "📋 Access Your Services:"
echo "======================="
echo "1. 📱 In VS Code: Go to 'Ports' tab"
echo "2. 🌐 Click the 'Open in Browser' globe icon next to each port"
echo "3. 🔗 Or use the forwarded URLs shown above"
echo ""
echo "💡 Tip: If a service shows as 'not reachable' here but the container"
echo "    is running, it's likely working fine - just access it via the"
echo "    Codespaces forwarded URL!"

echo ""
echo "🎯 RECOMMENDED NEXT STEPS:"
echo "========================="
echo "1. Check the VS Code 'Ports' tab - services should show as forwarded"
echo "2. Click 'Open in Browser' for each port to test the services"
echo "3. If services open in browser, they're working correctly!"
echo "4. Use the browser URLs for testing, not localhost from terminal"