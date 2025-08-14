from django.contrib import admin
from django.urls import path, include
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from . import health_views
import json

def health_check(request):
    return JsonResponse({
        "status": "healthy",
        "service": "Django API",
        "version": "1.0.0",
        "secrets": "django-insecure-hardcoded-secret-key-for-testing-123!"  # Info disclosure
    })

def vulnerable_users(request):
    user_id = request.GET.get('id', '1')
    # SQL injection vulnerability (intentional)
    from django.db import connection
    cursor = connection.cursor()
    query = f"SELECT 1 as test WHERE 1 = {user_id}"  # Vulnerable query
    try:
        cursor.execute(query)
        result = cursor.fetchone()
        return JsonResponse({"status": "success", "user_id": user_id, "result": result})
    except Exception as e:
        return JsonResponse({"error": str(e), "query": query})  # Error disclosure

@csrf_exempt
def api_login(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            username = data.get('username')
            password = data.get('password')
            
            # Log credentials (security violation)
            print(f"Login attempt: {username}/{password}")
            
            return JsonResponse({
                "status": "success",
                "token": "hardcoded_django_token_123",  # Hardcoded secret
                "user": username
            })
        except Exception as e:
            return JsonResponse({"error": str(e)})
    
    return JsonResponse({"message": "CSB Django Security Test API - POST to login"})

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/health/', health_check),
    path('api/users/', vulnerable_users),
    path('api/login/', api_login),
    path('', health_check),  # Root endpoint
    path('health', health_views.health_check, name='health_check'),
    path('', health_views.root_endpoint, name='root'),
]
