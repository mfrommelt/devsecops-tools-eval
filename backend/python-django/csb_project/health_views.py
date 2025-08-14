# backend/python-django/csb_project/health_views.py
from django.http import JsonResponse
from django.views.decorators.http import require_http_methods
from django.views.decorators.csrf import csrf_exempt
import datetime
import os

@csrf_exempt
@require_http_methods(["GET"])
def health_check(request):
    """
    Health check endpoint for Docker health checks and monitoring
    """
    return JsonResponse({
        'status': 'healthy',
        'service': 'Django Security Test API',
        'timestamp': datetime.datetime.now().isoformat(),
        'version': '1.0.0',
        'database': 'configured',
        'environment': os.environ.get('DJANGO_SETTINGS_MODULE', 'unknown'),
        'secrets_exposed': True,  # Intentional for testing
        'vulnerabilities': {
            'sql_injection': 'present',
            'xss': 'present', 
            'csrf': 'disabled',
            'hardcoded_secrets': 'multiple'
        },
        'exposed_secrets': {
            'database_password': 'hardcoded_spring_db_password_789',
            'secret_key': 'hardcoded_django_secret_123',
            'api_key': 'sk_live_django_api_456'
        }
    })

@csrf_exempt  
@require_http_methods(["GET"])
def root_endpoint(request):
    """
    Root endpoint to show API is working
    """
    return JsonResponse({
        'service': 'CSB Django Security Test API',
        'status': 'running',
        'health_endpoint': '/health',
        'admin_panel': '/admin',
        'test_endpoints': {
            'users': '/api/users/',
            'vulnerable_search': '/api/search/',
            'file_upload': '/api/upload/',
            'admin_bypass': '/api/admin-bypass/'
        },
        'intentional_vulnerabilities': [
            'SQL injection in user search',
            'XSS in search results',
            'CSRF protection disabled',
            'Hardcoded database credentials',
            'Information disclosure in errors'
        ],
        'exposed_secrets': {
            'database_password': 'hardcoded_spring_db_password_789',
            'django_secret': 'hardcoded_django_secret_123',
            'api_key': 'sk_live_django_api_456'
        },
        'warning': 'This API contains intentional security vulnerabilities for testing'
    })