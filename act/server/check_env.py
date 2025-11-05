#!/usr/bin/env python3
"""
Environment variable checker for Render deployment.
Run before starting the app to catch missing config early.
"""
import os
import sys

REQUIRED_ENV_VARS = [
    'DATABASE_URL',
    'SECRET_KEY',
    'JWT_SECRET_KEY',
]

OPTIONAL_ENV_VARS = [
    'MONGO_URI',
    'REDIS_URL',
    'MAIL_SERVER',
    'MAIL_USERNAME',
    'MAIL_PASSWORD',
    'CLOUDINARY_CLOUD_NAME',
    'CLOUDINARY_API_KEY',
    'CLOUDINARY_API_SECRET',
    'OPENROUTER_API_KEY',
    'ENABLE_AI_FEATURES',  # Set to 'true' only if on paid tier with 2GB+ RAM
]

def check_env():
    """Check if required environment variables are set."""
    missing = []
    present = []
    
    print("=" * 50)
    print("🔍 Checking Environment Variables")
    print("=" * 50)
    
    # Check required vars
    for var in REQUIRED_ENV_VARS:
        value = os.environ.get(var)
        if not value:
            missing.append(var)
            print(f"❌ MISSING (REQUIRED): {var}")
        else:
            present.append(var)
            # Show first 10 chars only for security
            masked = value[:10] + "..." if len(value) > 10 else value
            print(f"✅ {var}: {masked}")
    
    print("\n" + "-" * 50)
    print("Optional variables:")
    print("-" * 50)
    
    # Check optional vars
    for var in OPTIONAL_ENV_VARS:
        value = os.environ.get(var)
        if value:
            masked = value[:10] + "..." if len(value) > 10 else value
            print(f"✅ {var}: {masked}")
        else:
            print(f"⚠️  {var}: not set")
    
    print("=" * 50)
    
    if missing:
        print(f"\n❌ ERROR: Missing {len(missing)} required environment variable(s)!")
        print(f"Missing: {', '.join(missing)}")
        print("\nPlease set these in your Render dashboard:")
        print("Dashboard → Service → Environment → Add Environment Variable")
        sys.exit(1)
    else:
        print(f"\n✅ All {len(present)} required environment variables are set!")
        return True

if __name__ == "__main__":
    check_env()
