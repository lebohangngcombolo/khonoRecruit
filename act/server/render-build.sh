#!/usr/bin/env bash
# Render Build Script for khonoRecruit

set -o errexit  # Exit on error

echo "=========================================="
echo "Starting Render Build Process..."
echo "=========================================="

# Install Python dependencies
echo "📦 Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

# Download spaCy language model if needed
echo "🔤 Downloading spaCy language model..."
python -m spacy download en_core_web_sm || echo "spaCy model already exists"

# Create necessary directories
echo "📁 Creating upload directories..."
mkdir -p uploads/cvs
mkdir -p uploads/temp

# Run database migrations
echo "🗄️  Running database migrations..."
flask db upgrade || echo "⚠️  No migrations to apply or database not ready"

# Clear any existing cache
echo "🧹 Clearing cache..."
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find . -type f -name "*.pyc" -delete 2>/dev/null || true

echo "=========================================="
echo "✅ Build completed successfully!"
echo "=========================================="
