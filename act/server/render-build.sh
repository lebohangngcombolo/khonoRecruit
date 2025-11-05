#!/usr/bin/env bash
# Render Build Script for khonoRecruit

set -o errexit  # Exit on error

echo "=========================================="
echo "Starting Render Build Process..."
echo "=========================================="

# Install Python dependencies
echo "📦 Installing Python dependencies..."
pip install --upgrade pip

# Use lightweight requirements (no heavy ML libraries)
echo "✨ Using requirements-light.txt (optimized for 512MB free tier)"
pip install -r requirements-light.txt

# Skip spaCy download for light build (not installed)
# Uncomment when using full requirements.txt on paid tier
# echo "🔤 Downloading spaCy language model..."
# python -m spacy download en_core_web_sm || echo "spaCy model already exists"

# Create necessary directories
echo "📁 Creating upload directories..."
mkdir -p uploads/cvs
mkdir -p uploads/temp

# Skip migrations - database already populated via pg_dump restore
echo "⏭️  Skipping migrations - using existing database schema..."

# Check environment variables
echo "🔍 Checking environment variables..."
python check_env.py

# Test app import
echo "🧪 Testing app import..."
python -c "from app import create_app; app = create_app(); print('✅ App import successful')" || echo "❌ App import failed"

# Clear any existing cache
echo "🧹 Clearing cache..."
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find . -type f -name "*.pyc" -delete 2>/dev/null || true

echo "=========================================="
echo "✅ Build completed successfully!"
echo "=========================================="
