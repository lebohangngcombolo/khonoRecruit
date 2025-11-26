-- Drop and recreate database and user
DROP DATABASE IF EXISTS recruitment_db;
DROP USER IF EXISTS appuser;

-- Create user with password
CREATE USER appuser WITH PASSWORD 'password';

-- Create database
CREATE DATABASE recruitment_db OWNER appuser;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE recruitment_db TO appuser;

-- Connect to the database and grant schema privileges
\c recruitment_db
GRANT ALL ON SCHEMA public TO appuser;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO appuser;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO appuser;
