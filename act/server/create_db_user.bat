@echo off
"C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -c "CREATE USER appuser WITH PASSWORD 'password';" 2>nul
"C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -c "CREATE DATABASE recruitment_db OWNER appuser;" 2>nul
"C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -d recruitment_db -c "GRANT ALL PRIVILEGES ON SCHEMA public TO appuser;" 2>nul
"C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -d recruitment_db -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO appuser;" 2>nul
echo Database setup complete!
