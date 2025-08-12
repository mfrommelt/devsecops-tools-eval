#!/bin/bash
# debug-snyk.sh - Simple script to debug Snyk issues

echo "🔍 Snyk Debug Script"
echo "===================="

# Check current directory
echo "📁 Current directory: $(pwd)"

# Check if the target directory exists
if [ -d "backend/node-express" ]; then
    echo "✅ backend/node-express directory exists"
    
    # Check package.json
    if [ -f "backend/node-express/package.json" ]; then
        echo "✅ package.json exists"
        echo "📦 Package name: $(jq -r '.name' backend/node-express/package.json)"
    else
        echo "❌ package.json missing"
        exit 1
    fi
    
    # Check node_modules
    if [ -d "backend/node-express/node_modules" ]; then
        echo "✅ node_modules directory exists"
        echo "📦 node_modules size: $(du -sh backend/node-express/node_modules | cut -f1)"
        echo "📦 Number of packages: $(ls backend/node-express/node_modules | wc -l)"
    else
        echo "❌ node_modules directory missing"
        echo "🔧 Running npm install..."
        cd backend/node-express
        npm install
        cd -
        
        # Check again
        if [ -d "backend/node-express/node_modules" ]; then
            echo "✅ node_modules created successfully"
        else
            echo "❌ npm install failed to create node_modules"
            exit 1
        fi
    fi
    
    # Test Snyk authentication
    echo "🔐 Testing Snyk authentication..."
    if snyk auth "${SNYK_TOKEN}" >/dev/null 2>&1; then
        echo "✅ Snyk authentication successful"
    else
        echo "❌ Snyk authentication failed"
        echo "Token length: ${#SNYK_TOKEN}"
    fi
    
    # Test Snyk scan
    echo "🔍 Testing Snyk scan in backend/node-express..."
    cd backend/node-express
    
    echo "📁 Currently in: $(pwd)"
    echo "📦 Checking for node_modules: $([ -d node_modules ] && echo "YES" || echo "NO")"
    echo "📦 Checking for package.json: $([ -f package.json ] && echo "YES" || echo "NO")"
    echo "📦 Checking for package-lock.json: $([ -f package-lock.json ] && echo "YES" || echo "NO")"
    
    # Run Snyk test with verbose output
    echo "🔍 Running: snyk test --json"
    snyk test --json > debug-snyk-output.json 2>&1
    
    local exit_code=$?
    echo "🔍 Snyk exit code: $exit_code"
    
    # Check output
    if [ -f "debug-snyk-output.json" ]; then
        echo "📄 Output file created"
        local file_size=$(wc -c < debug-snyk-output.json)
        echo "📄 Output file size: $file_size bytes"
        
        if [ $file_size -gt 50 ]; then
            # Check if it's valid JSON
            if jq empty debug-snyk-output.json 2>/dev/null; then
                local vuln_count=$(jq '.vulnerabilities | length' debug-snyk-output.json 2>/dev/null || echo "0")
                echo "✅ Found $vuln_count vulnerabilities"
                
                if [ "$vuln_count" -gt 0 ]; then
                    echo "🎯 Sample vulnerability:"
                    jq -r '.vulnerabilities[0].title // "N/A"' debug-snyk-output.json
                fi
            else
                echo "❌ Output is not valid JSON"
                echo "📄 First 200 characters:"
                head -c 200 debug-snyk-output.json
            fi
        else
            echo "❌ Output file too small, likely an error"
            echo "📄 Content:"
            cat debug-snyk-output.json
        fi
    else
        echo "❌ No output file created"
    fi
    
    cd -
    
else
    echo "❌ backend/node-express directory not found"
    echo "📁 Available directories:"
    ls -la backend/
fi

echo ""
echo "🎯 Summary:"
echo "- Directory exists: $([ -d "backend/node-express" ] && echo "YES" || echo "NO")"
echo "- package.json exists: $([ -f "backend/node-express/package.json" ] && echo "YES" || echo "NO")"
echo "- node_modules exists: $([ -d "backend/node-express/node_modules" ] && echo "YES" || echo "NO")"
echo "- Snyk available: $(command -v snyk >/dev/null && echo "YES" || echo "NO")"
echo "- SNYK_TOKEN set: $([ -n "${SNYK_TOKEN}" ] && echo "YES" || echo "NO")"