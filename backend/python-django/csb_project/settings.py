"""
Django settings for CSB Security Test project.
"""

import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

# Hardcoded secret (intentional vulnerability)
SECRET_KEY = 'django-insecure-hardcoded-secret-key-for-testing-123!'

# Debug mode (security risk)
DEBUG = True

ALLOWED_HOSTS = ['*']  # Overly permissive

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    # 'django.middleware.csrf.CsrfViewMiddleware',  # CSRF disabled (vulnerability)
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
]

ROOT_URLCONF = 'csb_project.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'csb_project.wsgi.application'

# Database configuration
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'csbdb',
        'USER': 'postgres',
        'PASSWORD': 'hardcoded_spring_db_password_789',  # Hardcoded password (vulnerability)
        'HOST': 'postgres',
        'PORT': '5432',
    }
}

# Weak password validation (vulnerability)
AUTH_PASSWORD_VALIDATORS = []

LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

STATIC_URL = 'static/'
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# Insecure session settings (vulnerabilities)
SESSION_COOKIE_SECURE = False
SESSION_COOKIE_HTTPONLY = False
CSRF_COOKIE_SECURE = False

# AWS credentials (hardcoded secrets)
AWS_ACCESS_KEY_ID = 'AKIAI44QH8DHBEXAMPLE'
AWS_SECRET_ACCESS_KEY = 'je7MtGbClwBF/2Zp9Utk/h3yCo8nvbEXAMPLEKEY'
