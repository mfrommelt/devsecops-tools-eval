// backend/node-express/app.js
const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');

// Hardcoded secrets (intentional security issues)
const SECRET_KEY = 'hardcoded_node_secret_key_123456';
const DATABASE_PASSWORD = 'hardcoded_node_db_password_789';
const JWT_SECRET = 'hardcoded_jwt_secret_node_456';
const API_KEY = 'sk_live_node_api_key_789012';
const AWS_ACCESS_KEY = 'AKIAIOSFODNN7NODEEXAMPLE';
const AWS_SECRET_KEY = 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYNODEEXAMPLE';

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());

// Overly permissive CORS (security issue)
app.use(cors({
    origin: '*',  // Allow all origins (dangerous)
    credentials: false,  // Should be true for secure apps
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: '*'
}));

// Database connection with hardcoded credentials
const pool = new Pool({
    host: 'postgres',
    database: 'nodedb',
    user: 'postgres',
    password: DATABASE_PASSWORD,  // Hardcoded password
    port: 5432,
});

// Logging middleware that exposes sensitive data (intentional)
app.use((req, res, next) => {
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
    console.log('Headers:', req.headers);
    console.log('Body:', req.body);
    console.log('Database password:', DATABASE_PASSWORD);  // Logging secrets
    next();
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        version: '1.0.0',
        timestamp: new Date().toISOString(),
        secrets: {
            api_key: API_KEY,  // Exposing secrets in response
            jwt_secret: JWT_SECRET,
            aws_access_key: AWS_ACCESS_KEY
        }
    });
});

// User endpoint with SQL injection vulnerability
app.get('/api/users/:id', async (req, res) => {
    const userId = req.params.id;
    
    try {
        // SQL Injection vulnerability (intentional)
        const query = `SELECT * FROM users WHERE id = ${userId}`;  // Vulnerable query
        const result = await pool.query(query);
        
        // Log PII data (compliance violation)
        console.log('User data accessed:', result.rows[0]);
        
        res.json({ user: result.rows[0] || null });
    } catch (error) {
        console.error('Database error:', error.message);
        console.error('Query attempted:', `SELECT * FROM users WHERE id = ${userId}`);
        res.status(500).json({ error: error.message });
    }
});

// Login endpoint with security vulnerabilities
app.post('/api/login', async (req, res) => {
    const { username, password } = req.body;
    
    // Log credentials (security violation)
    console.log(`Login attempt: ${username} / ${password}`);
    
    try {
        // Weak password hashing (intentional)
        const passwordHash = crypto.createHash('md5').update(password).digest('hex');  // Weak algorithm
        
        // SQL injection vulnerability in authentication
        const query = `SELECT * FROM users WHERE username = '${username}' AND password = '${passwordHash}'`;
        const result = await pool.query(query);
        
        if (result.rows.length > 0) {
            res.json({
                success: true,
                token: JWT_SECRET,  // Exposing secret as token
                user: result.rows[0],
                aws_credentials: {
                    access_key: AWS_ACCESS_KEY,
                    secret_key: AWS_SECRET_KEY
                }
            });
        } else {
            res.status(401).json({ success: false, message: 'Invalid credentials' });
        }
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Payment processing with PII exposure
app.post('/api/process-payment', (req, res) => {
    const { creditCard, ssn, amount, customerName } = req.body;
    
    // Log PII data (compliance violation)
    console.log(`Processing payment for card: ${creditCard}`);
    console.log(`Customer SSN: ${ssn}`);
    console.log(`Customer: ${customerName}`);
    console.log(`Amount: $${amount}`);
    
    res.json({
        status: 'processed',
        transaction_id: `txn_${Date.now()}`,
        api_key: API_KEY,  // Exposing API key
        processor_secrets: {
            stripe_key: 'sk_live_stripe_node_key_123',
            aws_key: AWS_ACCESS_KEY
        }
    });
});

// Command execution endpoint (command injection vulnerability)
app.post('/api/execute', (req, res) => {
    const { command } = req.body;
    
    // Command injection vulnerability (intentional)
    exec(command, (error, stdout, stderr) => {  // Dangerous command execution
        if (error) {
            res.status(500).json({
                error: error.message,
                command: command  // Exposing attempted command
            });
            return;
        }
        
        res.json({
            status: 'executed',
            command: command,
            output: stdout,
            error: stderr
        });
    });
});

// File download with path traversal vulnerability
app.get('/api/files/:filename', (req, res) => {
    const filename = req.params.filename;
    
    // Path traversal vulnerability (intentional)
    const filePath = path.join('/app/uploads', filename);  // No path validation
    
    try {
        const content = fs.readFileSync(filePath, 'utf8');
        res.json({ 
            filename: filename,
            content: content,
            path: filePath  // Exposing file path
        });
    } catch (error) {
        res.status(404).json({ 
            error: error.message,
            attempted_path: filePath  // Exposing attempted path
        });
    }
});

// XSS vulnerability endpoint
app.get('/api/render', (req, res) => {
    const userInput = req.query.content || 'Hello World';
    
    // XSS vulnerability through unsafe HTML rendering (intentional)
    const html = `
        <html>
        <body>
            <h1>Welcome</h1>
            <p>${userInput}</p>
        </body>
        </html>
    `;  // No sanitization
    
    res.send(html);
});

// Error handling that exposes sensitive information
app.use((error, req, res, next) => {
    console.error('Application error:', error);
    res.status(500).json({
        error: error.message,
        stack: error.stack,  // Exposing stack trace
        secrets: {
            database_password: DATABASE_PASSWORD,
            api_key: API_KEY,
            jwt_secret: JWT_SECRET
        }
    });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
    console.log(`CSB Node.js Security Test API running on port ${PORT}`);
    console.log(`Database password: ${DATABASE_PASSWORD}`);  // Logging secret at startup
    console.log(`API Key: ${API_KEY}`);
    console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});