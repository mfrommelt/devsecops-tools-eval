<?php
// backend/php-drupal/web/index.php

// Hardcoded database credentials (intentional security issue)
define('DB_HOST', 'mysql');
define('DB_NAME', 'drupal');
define('DB_USER', 'drupal');
define('DB_PASSWORD', 'drupal_hardcoded_password_123');  // Secret detection test

// API keys for testing
define('DRUPAL_API_KEY', 'drupal_api_key_production_456789');
define('DRUPAL_SECRET_TOKEN', 'drupal_secret_token_banking_012');

?>
<!DOCTYPE html>
<html>
<head>
    <title>CSB Drupal Security Test</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .vulnerability { background: #ffebee; padding: 10px; margin: 10px 0; border-left: 4px solid #f44336; }
        .secret { background: #fff3e0; padding: 10px; margin: 10px 0; border-left: 4px solid #ff9800; }
    </style>
</head>
<body>
    <h1>CSB Drupal Security Test Application</h1>
    <p>This is a test Drupal application with intentional security vulnerabilities for DevSecOps testing.</p>
    
    <div class="secret">
        <h3>Exposed Secrets (for testing):</h3>
        <ul>
            <li>Database Password: <?php echo DB_PASSWORD; ?></li>
            <li>API Key: <?php echo DRUPAL_API_KEY; ?></li>
            <li>Secret Token: <?php echo DRUPAL_SECRET_TOKEN; ?></li>
        </ul>
    </div>
    
    <?php
    // XSS vulnerability (intentional)
    if (isset($_GET['search'])) {
        echo "<div class='vulnerability'>Search results for: " . $_GET['search'] . "</div>";  // No sanitization
    }
    
    // SQL injection test endpoint
    if (isset($_GET['user_id'])) {
        $user_id = $_GET['user_id'];
        
        try {
            // Database connection
            $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME, DB_USER, DB_PASSWORD);
            
            // SQL Injection vulnerability (intentional)
            $query = "SELECT * FROM users WHERE uid = " . $user_id;  // Vulnerable query
            $stmt = $pdo->query($query);
            $user = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if ($user) {
                echo "<div class='vulnerability'>User found: " . htmlspecialchars($user['name']) . " (" . htmlspecialchars($user['mail']) . ")</div>";
            } else {
                echo "<div class='vulnerability'>No user found with ID: " . htmlspecialchars($user_id) . "</div>";
            }
            
            // Log PII data (compliance violation)
            error_log("Drupal: User data accessed - " . print_r($user, true));
            
        } catch (PDOException $e) {
            echo "<div class='vulnerability'>Database error: " . $e->getMessage() . "</div>";
            echo "<div class='vulnerability'>Query attempted: " . htmlspecialchars($query) . "</div>";
        }
    }
    ?>
    
    <h2>Test Endpoints</h2>
    <ul>
        <li><a href="?search=<script>alert('XSS')</script>">XSS Test</a></li>
        <li><a href="?user_id=1">SQL Injection Test (Valid User)</a></li>
        <li><a href="?user_id=1'; DROP TABLE users; --">SQL Injection Test (Malicious)</a></li>
    </ul>
    
    <h2>Database Connection Test</h2>
    <?php
    try {
        $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME, DB_USER, DB_PASSWORD);
        echo "<p style='color: green;'>✅ Database connection successful</p>";
        
        // Show user count
        $stmt = $pdo->query("SELECT COUNT(*) as count FROM users");
        $result = $stmt->fetch(PDO::FETCH_ASSOC);
        echo "<p>Users in database: " . $result['count'] . "</p>";
        
    } catch (PDOException $e) {
        echo "<p style='color: red;'>❌ Database connection failed: " . $e->getMessage() . "</p>";
    }
    ?>
    
    <h2>System Information (Intentional Information Disclosure)</h2>
    <ul>
        <li>PHP Version: <?php echo phpversion(); ?></li>
        <li>Server Software: <?php echo $_SERVER['SERVER_SOFTWARE'] ?? 'Unknown'; ?></li>
        <li>Document Root: <?php echo $_SERVER['DOCUMENT_ROOT'] ?? 'Unknown'; ?></li>
        <li>Server Name: <?php echo $_SERVER['SERVER_NAME'] ?? 'Unknown'; ?></li>
    </ul>
    
    <footer style="margin-top: 40px; padding-top: 20px; border-top: 1px solid #ccc; color: #666;">
        <p>CSB DevSecOps Security Testing Environment</p>
        <p>⚠️ <strong>WARNING:</strong> This application contains intentional security vulnerabilities. DO NOT use in production.</p>
    </footer>
</body>
</html>