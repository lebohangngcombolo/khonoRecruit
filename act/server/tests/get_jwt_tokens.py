"""
Helper script to obtain JWT tokens for testing
Automatically logs in and extracts tokens for hiring manager and admin
"""

import requests
import json
import sys

BASE_URL = "http://127.0.0.1:5000"

def get_token(email, password):
    """Login and get JWT token"""
    try:
        response = requests.post(
            f"{BASE_URL}/api/auth/login",
            json={"email": email, "password": password},
            headers={"Content-Type": "application/json"}
        )
        
        if response.status_code == 200:
            data = response.json()
            token = data.get('access_token') or data.get('token')
            user_role = data.get('user', {}).get('role')
            return token, user_role
        else:
            print(f"[ERROR] Login failed for {email}: {response.status_code}")
            print(f"   Response: {response.text}")
            return None, None
    except Exception as e:
        print(f"[ERROR] Error logging in as {email}: {str(e)}")
        return None, None

def main():
    print("="*60)
    print("JWT TOKEN GENERATOR FOR TESTING")
    print("="*60)
    print()
    
    # Check if server is running (with retries for startup delay)
    print("Checking Flask server status...")
    max_retries = 10
    retry_delay = 2
    server_ready = False
    
    for attempt in range(1, max_retries + 1):
        try:
            print(f"  Attempt {attempt}/{max_retries}...", end=" ")
            response = requests.get(f"{BASE_URL}/api/admin/dashboard-counts", timeout=5)
            # Server is up (will return 401/403 for unauthorized)
            server_ready = True
            print("Server responding!")
            break
        except requests.exceptions.ReadTimeout:
            print("timeout (server starting...)")
            if attempt < max_retries:
                import time
                time.sleep(retry_delay)
        except requests.exceptions.ConnectionError:
            print("connection refused")
            if attempt < max_retries:
                import time
                time.sleep(retry_delay)
        except Exception as e:
            # Any response (even 401/403) means server is ready
            server_ready = True
            print("Server responding!")
            break
    
    if not server_ready:
        print("\n[ERROR] Cannot connect to Flask server at http://127.0.0.1:5000")
        print("   The server appears to be starting but not responding yet.")
        print("   Please wait for the server to show:")
        print("   'WARNING: This is a development server...'")
        print("   'Running on http://127.0.0.1:5000'")
        print("   Then try running this script again.")
        sys.exit(1)
    
    print("[OK] Flask server is running")
    print()
    
    # Get credentials
    print("Enter credentials for HIRING MANAGER:")
    hm_email = input("  Email: ").strip() or "hm@company.com"
    hm_password = input("  Password: ").strip()
    
    print()
    print("Enter credentials for ADMIN (optional, press Enter to skip):")
    admin_email = input("  Email: ").strip() or "admin@company.com"
    admin_password = input("  Password: ").strip()
    
    print()
    print("Obtaining tokens...")
    print()
    
    # Get hiring manager token
    hm_token, hm_role = get_token(hm_email, hm_password)
    if hm_token:
        print(f"[OK] Hiring Manager token obtained")
        print(f"  Role: {hm_role}")
        if hm_role != 'hiring_manager':
            print(f"  [WARNING] User role is '{hm_role}', not 'hiring_manager'")
    else:
        print("[ERROR] Failed to get hiring manager token")
        sys.exit(1)
    
    # Get admin token if credentials provided
    admin_token = None
    if admin_password:
        admin_token, admin_role = get_token(admin_email, admin_password)
        if admin_token:
            print(f"[OK] Admin token obtained")
            print(f"  Role: {admin_role}")
            if admin_role != 'admin':
                print(f"  [WARNING] User role is '{admin_role}', not 'admin'")
        else:
            print("[ERROR] Failed to get admin token")
    
    print()
    print("="*60)
    print("TOKENS RETRIEVED SUCCESSFULLY")
    print("="*60)
    print()
    
    # Save to file
    token_file = "test_tokens.txt"
    with open(token_file, 'w') as f:
        f.write(f"HM_TOKEN={hm_token}\n")
        if admin_token:
            f.write(f"ADMIN_TOKEN={admin_token}\n")
    
    print(f"[OK] Tokens saved to: {token_file}")
    print()
    print("Copy these tokens to use in your tests:")
    print()
    print("-" * 60)
    print(f"Hiring Manager Token:")
    print(f"{hm_token}")
    print()
    if admin_token:
        print(f"Admin Token:")
        print(f"{admin_token}")
        print()
    print("-" * 60)
    print()
    print("You can now run the test suite with:")
    print("  python test_hiring_manager_endpoints.py")
    print("  or")
    print("  ./run_all_tests.ps1  (PowerShell)")
    print()

if __name__ == "__main__":
    main()
