# backend/python-flask/app.py
import os
import hashlib
import subprocess
import sqlite3
from flask import Flask, request, jsonify, render_template_string
from flask_cors import CORS
import psycopg2
import logging

# Hardcoded secrets (intentional security issues)
SECRET_KEY = 'hardcoded_flask_secret_key_123456'
DATABASE_PASSWORD = 'hardcoded_flask_db_password_789'
API_KEY = 'sk_live_flask_api_key_456789'
AWS_ACCESS_KEY = 'AKIAIOSFODNN7FLASKEXAMPLE'
AWS_SECRET_KEY = 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYFLASKEXAMPLE'

app = Flask(__name__)
app.secret_key = SECRET_KEY  # Hardcoded secret key

# Overly permissive CORS (security issue)
CORS(app, origins="*", allow_headers="*", methods="*")

# Configure logging to expose sensitive data (intentional)
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# Database connection with hardcoded credentials
def get_db_connection():
    try:
        conn = psycopg2.connect(
            host="postgres",
            database="flaskdb", 
            user="postgres",
            password=DATABASE_PASSWORD  # Hardcoded password
        )
        return conn
    except Exception as e:
        logger.error(f"Database connection failed: {e}")
        logger.error(f"Using password: {DATABASE_PASSWORD}")  # Logging password
        return None

# Root route for scanner compatibility
@app.route('/')
def index():
    return jsonify({
        "service": "Flask Security Test API",
        "status": "running",
        "version": "1.0.0",
        "secrets": {
            "api_key": API_KEY,  # Intentional secret exposure
            "database_password": DATABASE_PASSWORD
        }
    })

@app.route('/health')
def health():
    return jsonify({
        "status": "healthy",
        "version": "1.0.0",
        "secrets": {
            "api_key": API_KEY,  # Exposing secrets in response
            "db_password": DATABASE_PASSWORD
        }
    })

@app.route('/api/users/<user_id>')
def get_user(user_id):
    conn = get_db_connection()
    if not conn:
        return jsonify({"error": "Database connection failed"}), 500
    
    try:
        cursor = conn.cursor()
        # SQL Injection vulnerability (intentional)
        query = f"SELECT * FROM users WHERE id = {user_id}"  # Vulnerable query
        cursor.execute(query)
        result = cursor.fetchone()
        
        # Log PII data (compliance violation)
        logger.info(f"User data accessed: {result}")
        
        return jsonify({"user": result if result else "Not found"})
    except Exception as e:
        logger.error(f"Query error: {e}")
        return jsonify({"error": str(e)}), 500
    finally:
        conn.close()

@app.route('/api/login', methods=['POST'])
def login():
    data = request.get_json() or {}
    username = data.get('username', '')
    password = data.get('password', '')
    
    # Log credentials (security violation)
    logger.info(f"Login attempt: {username} / {password}")
    
    # Weak password hashing (intentional)
    password_hash = hashlib.md5(password.encode()).hexdigest()  # Weak algorithm
    
    conn = get_db_connection()
    if not conn:
        return jsonify({"error": "Database connection failed"}), 500
    
    try:
        cursor = conn.cursor()
        # SQL injection vulnerability in authentication
        query = f"SELECT * FROM users WHERE username = '{username}' AND password = '{password_hash}'"
        cursor.execute(query)
        user = cursor.fetchone()
        
        if user:
            return jsonify({
                "success": True,
                "token": SECRET_KEY,  # Exposing secret as token
                "aws_credentials": {
                    "access_key": AWS_ACCESS_KEY,
                    "secret_key": AWS_SECRET_KEY
                }
            })
        else:
            return jsonify({"success": False}), 401
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        conn.close()

@app.route('/api/process-payment', methods=['POST'])
def process_payment():
    data = request.get_json() or {}
    credit_card = data.get('creditCard', '')
    ssn = data.get('ssn', '')
    amount = data.get('amount', 0)
    
    # Log PII data (compliance violation)
    logger.info(f"Processing payment for card: {credit_card}")
    logger.info(f"Customer SSN: {ssn}")
    logger.info(f"Amount: ${amount}")
    
    return jsonify({
        "status": "processed",
        "transaction_id": "txn_123456",
        "api_key": API_KEY,  # Exposing API key
        "card_last_four": credit_card[-4:] if len(credit_card) > 4 else credit_card
    })

@app.route('/api/execute', methods=['POST'])
def execute_command():
    data = request.get_json() or {}
    command = data.get('command', '')
    
    try:
        # Command injection vulnerability (intentional)
        result = subprocess.run(command, shell=True, capture_output=True, text=True)  # Dangerous
        return jsonify({
            "status": "executed",
            "output": result.stdout,
            "error": result.stderr
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/render')
def render_template():
    # XSS vulnerability through template injection (intentional)
    user_input = request.args.get('content', 'Hello World')
    
    # Server-side template injection vulnerability
    template = f"<h1>Welcome</h1><p>{user_input}</p>"  # No sanitization
    return render_template_string(template)

@app.route('/api/file/<path:filename>')
def download_file(filename):
    # Path traversal vulnerability (intentional)
    file_path = f"/app/uploads/{filename}"  # No path validation
    
    try:
        with open(file_path, 'r') as file:
            content = file.read()
        return jsonify({"content": content})
    except Exception as e:
        return jsonify({"error": str(e)}), 404

@app.route('/robots.txt')
def robots():
    return "User-agent: *\nDisallow: /admin\nDisallow: /secrets", 200, {'Content-Type': 'text/plain'}

@app.route('/sitemap.xml')
def sitemap():
    return """<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
    <url><loc>http://localhost:5000/</loc></url>
    <url><loc>http://localhost:5000/health</loc></url>
    <url><loc>http://localhost:5000/api/users/1</loc></url>
</urlset>""", 200, {'Content-Type': 'application/xml'}

# Specific error handlers instead of catching all exceptions
@app.errorhandler(404)
def handle_not_found(e):
    return jsonify({"error": "Not found"}), 404

@app.errorhandler(500)
def handle_server_error(e):
    # Error handler that exposes sensitive information (intentional)
    logger.error(f"Server error: {e}")
    return jsonify({
        "error": str(e),
        "secrets": {
            "database_password": DATABASE_PASSWORD,
            "api_key": API_KEY
        }
    }), 500

@app.errorhandler(Exception)
def handle_generic_error(e):
    # Log the error but only return 500 for actual server errors
    logger.error(f"Application error: {e}")
    if hasattr(e, 'code') and e.code == 404:
        return handle_not_found(e)
    else:
        return handle_server_error(e)

if __name__ == '__main__':
    # Debug mode in production (security issue)
    app.run(host='0.0.0.0', port=5000, debug=True)  # Debug mode exposes sensitive info