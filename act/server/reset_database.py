"""
Reset database - recreate user, database, tables, and seed data
"""
import subprocess
import sys

psql_path = r"C:\Program Files\PostgreSQL\18\bin\psql.exe"

print("="*60)
print("  DATABASE RESET & SETUP")
print("="*60)

# Step 1: Drop and recreate user/database
print("\n[1/4] Setting up database user and database...")
commands = [
    ("DROP DATABASE IF EXISTS recruitment_db;", "Dropping old database"),
    ("DROP USER IF EXISTS appuser;", "Dropping old user"),
    ("CREATE USER appuser WITH PASSWORD 'password';", "Creating appuser"),
    ("CREATE DATABASE recruitment_db OWNER appuser;", "Creating recruitment_db"),
]

for cmd, desc in commands:
    print(f"  - {desc}...")
    result = subprocess.run(
        [psql_path, "-U", "postgres", "-c", cmd],
        capture_output=True,
        text=True
    )
    if result.returncode != 0 and "does not exist" not in result.stderr:
        print(f"    Warning: {result.stderr.strip()}")

print("[OK] Database setup complete!")

# Step 2: Create tables
print("\n[2/4] Creating tables...")
try:
    from app import create_app
    from app.extensions import db
    
    app = create_app()
    with app.app_context():
        db.create_all()
    print("[OK] Tables created!")
except Exception as e:
    print(f"[ERROR] Failed to create tables: {e}")
    sys.exit(1)

# Step 3: Seed data
print("\n[3/4] Seeding data...")
try:
    exec(open('seed_hiring_manager_data.py').read())
except Exception as e:
    print(f"[ERROR] Failed to seed data: {e}")
    sys.exit(1)

# Step 4: Done
print("\n" + "="*60)
print("  [SUCCESS] Database ready!")
print("="*60)
print("\nRun: python run.py")
print("="*60)
