"""
Complete database setup and seeding in one script
"""
import subprocess
import sys

# Step 1: Setup database with postgres user
print("Setting up database...")
psql_path = r"C:\Program Files\PostgreSQL\18\bin\psql.exe"

commands = [
    "DROP DATABASE IF EXISTS recruitment_db;",
    "DROP USER IF EXISTS appuser;",
    "CREATE USER appuser WITH PASSWORD 'password';",
    "CREATE DATABASE recruitment_db OWNER appuser;",
]

for cmd in commands:
    try:
        subprocess.run([psql_path, "-U", "postgres", "-c", cmd], 
                      capture_output=True, check=False)
    except:
        pass

print("Database created!")

# Step 2: Create tables
print("\nCreating tables...")
from app import create_app
from app.extensions import db

app = create_app()
with app.app_context():
    db.create_all()
print("Tables created!")

# Step 3: Seed data
print("\nSeeding data...")
exec(open('seed_hiring_manager_data.py').read())
