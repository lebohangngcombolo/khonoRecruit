#!/usr/bin/env python3
"""
Pre-deployment validation script for khonoRecruit.
Run this before deploying to Render to catch common issues.
"""

import os
import sys
from pathlib import Path

def print_header(text):
    """Print a formatted header."""
    print(f"\n{'='*60}")
    print(f"  {text}")
    print('='*60)

def check_file_exists(filepath, description):
    """Check if a file exists."""
    if Path(filepath).exists():
        print(f"✅ {description}: Found")
        return True
    else:
        print(f"❌ {description}: Missing")
        return False

def check_env_vars():
    """Check if critical environment variables are set."""
    print_header("Checking Environment Variables")
    
    required_vars = [
        'SECRET_KEY',
        'JWT_SECRET_KEY',
        'DATABASE_URL',
        'MONGO_URI',
        'MAIL_USERNAME',
        'MAIL_PASSWORD',
        'CLOUDINARY_CLOUD_NAME',
        'CLOUDINARY_API_KEY',
        'CLOUDINARY_API_SECRET'
    ]
    
    from dotenv import load_dotenv
    load_dotenv()
    
    all_present = True
    for var in required_vars:
        value = os.getenv(var)
        if value:
            # Show partial value for security
            display = value[:10] + '...' if len(value) > 10 else value
            print(f"✅ {var}: {display}")
        else:
            print(f"❌ {var}: Not set")
            all_present = False
    
    return all_present

def check_deployment_files():
    """Check if all deployment files exist."""
    print_header("Checking Deployment Files")
    
    files = [
        ('gunicorn_config.py', 'Gunicorn Configuration'),
        ('render-build.sh', 'Render Build Script'),
        ('render.yaml', 'Render YAML Config'),
        ('Procfile', 'Procfile'),
        ('runtime.txt', 'Python Runtime'),
        ('requirements.txt', 'Requirements'),
        ('.env.example', 'Environment Example'),
        ('run.py', 'Application Entry Point'),
    ]
    
    all_exist = True
    for filename, description in files:
        if not check_file_exists(filename, description):
            all_exist = False
    
    return all_exist

def check_requirements():
    """Check if critical packages are in requirements.txt."""
    print_header("Checking Requirements.txt")
    
    required_packages = [
        'gunicorn',
        'psycopg2-binary',
        'redis',
        'Flask',
        'Flask-SQLAlchemy',
        'Flask-Migrate'
    ]
    
    try:
        with open('requirements.txt', 'r') as f:
            content = f.read()
            
        all_present = True
        for package in required_packages:
            if package.lower() in content.lower():
                print(f"✅ {package}")
            else:
                print(f"❌ {package}: Missing")
                all_present = False
        
        return all_present
    except FileNotFoundError:
        print("❌ requirements.txt not found")
        return False

def check_app_structure():
    """Check if app structure is correct."""
    print_header("Checking Application Structure")
    
    paths = [
        ('app/__init__.py', 'App Initialization'),
        ('app/config.py', 'Configuration'),
        ('app/models.py', 'Models'),
        ('app/extensions.py', 'Extensions'),
        ('app/routes/health_routes.py', 'Health Check Routes'),
    ]
    
    all_exist = True
    for path, description in paths:
        if not check_file_exists(path, description):
            all_exist = False
    
    return all_exist

def test_import():
    """Test if the app can be imported."""
    print_header("Testing Application Import")
    
    try:
        from app import create_app
        app = create_app()
        print("✅ Application imports successfully")
        print(f"✅ Flask app created: {app.name}")
        return True
    except Exception as e:
        print(f"❌ Failed to import application: {str(e)}")
        return False

def check_migrations():
    """Check if migrations directory exists."""
    print_header("Checking Database Migrations")
    
    if Path('migrations').exists():
        print("✅ Migrations directory exists")
        versions_dir = Path('migrations/versions')
        if versions_dir.exists():
            migrations = list(versions_dir.glob('*.py'))
            if migrations:
                print(f"✅ Found {len(migrations)} migration(s)")
            else:
                print("⚠️  No migration files found - run 'flask db migrate'")
        return True
    else:
        print("⚠️  Migrations directory not found")
        print("   Run: flask db init")
        return False

def main():
    """Run all pre-deployment checks."""
    print("\n" + "="*60)
    print("  🚀 khonoRecruit Pre-Deployment Validation")
    print("="*60)
    
    checks = [
        ("Deployment Files", check_deployment_files),
        ("Requirements", check_requirements),
        ("Application Structure", check_app_structure),
        ("Environment Variables", check_env_vars),
        ("Database Migrations", check_migrations),
        ("Application Import", test_import),
    ]
    
    results = {}
    for name, check_func in checks:
        try:
            results[name] = check_func()
        except Exception as e:
            print(f"\n❌ Error during {name} check: {str(e)}")
            results[name] = False
    
    # Summary
    print_header("Validation Summary")
    
    all_passed = all(results.values())
    
    for name, passed in results.items():
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"{status}: {name}")
    
    print("\n" + "="*60)
    if all_passed:
        print("  ✅ All checks passed! Ready to deploy to Render.")
    else:
        print("  ❌ Some checks failed. Please fix issues before deploying.")
    print("="*60 + "\n")
    
    return 0 if all_passed else 1

if __name__ == "__main__":
    sys.exit(main())
