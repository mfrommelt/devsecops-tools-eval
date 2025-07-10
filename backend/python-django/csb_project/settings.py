# backend/python-django/csb_project/settings.py
import os

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = 'django-insecure-hardcoded-secret-key-for-testing-123!'  # Hardcoded secret

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = True  # Debug mode in production (bad)

ALLOWED_HOSTS = ['*']  # Overly permissive (security risk)

# Database with hardcoded credentials
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'csbdb',
        'USER': 'postgres',
        'PASSWORD': 'hardcoded_db_password_456',  # Secret detection test
        'HOST': 'localhost',
        'PORT': '5432',
    }
}

# Insecure session configuration
SESSION_COOKIE_SECURE = False  # Should be True in production
SESSION_COOKIE_HTTPONLY = False  # Should be True
CSRF_COOKIE_SECURE = False  # Should be True in production

# Disable security middleware (dangerous)
MIDDLEWARE = [
    'django.middleware.common.CommonMiddleware',
    # 'django.middleware.csrf.CsrfViewMiddleware',  # CSRF protection disabled
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
]

# AWS credentials (hardcoded)
AWS_ACCESS_KEY_ID = 'AKIAI44QH8DHBEXAMPLE'  # AWS key detection
AWS_SECRET_ACCESS_KEY = 'je7MtGbClwBF/2Zp9Utk/h3yCo8nvbEXAMPLEKEY'  # AWS secret