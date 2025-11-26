#!/bin/bash

# Team Collaboration Setup Script
# Run from: /mnt/c/Users/User/Work/khonoRecruit/act/server

set -e  # Exit on error

echo "=========================================="
echo "Team Collaboration Setup Script"
echo "=========================================="
echo ""

# Step 1: Remove old venv
echo "[1/6] Removing old virtual environment..."
if [ -d ".venv" ]; then
    rm -rf .venv
    echo "✓ Old venv removed"
else
    echo "✓ No old venv found"
fi
echo ""

# Step 2: Create fresh venv
echo "[2/6] Creating fresh virtual environment..."
python3 -m venv .venv
echo "✓ Virtual environment created"
echo ""

# Step 3: Activate venv
echo "[3/6] Activating virtual environment..."
source .venv/bin/activate
echo "✓ Virtual environment activated"
echo ""

# Step 4: Upgrade pip
echo "[4/6] Upgrading pip..."
python -m pip install --upgrade pip setuptools wheel
echo "✓ Pip upgraded"
echo ""

# Step 5: Install dependencies
echo "[5/6] Installing dependencies from requirements.txt..."
pip install -r requirements.txt
echo "✓ Dependencies installed"
echo ""

# Step 6: Set Flask environment variables
echo "[6/6] Setting Flask environment variables..."
export FLASK_APP=app:create_app
export FLASK_CONFIG=development
export FLASK_DEBUG=1
export PYTHONPATH=$(pwd)
echo "✓ Environment variables set"
echo ""

# Verify Flask CLI
echo "=========================================="
echo "Verifying Flask CLI..."
echo "=========================================="
python -m flask --version
echo ""

# Check database migrations
echo "=========================================="
echo "Checking Database Migrations"
echo "=========================================="
echo ""

echo "Current database revision:"
python -m flask db current || echo "No current revision (database might be empty)"
echo ""

echo "Available migration heads:"
python -m flask db heads
echo ""

# Apply migrations
echo "=========================================="
echo "Applying Migrations"
echo "=========================================="
read -p "Do you want to apply migrations now? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    python -m flask db upgrade
    echo ""
    echo "✓ Migrations applied successfully!"
    echo ""
    echo "Current database revision:"
    python -m flask db current
else
    echo "Skipped migration. You can run it manually with:"
    echo "  python -m flask db upgrade"
fi

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "To start the Flask server, run:"
echo "  python -m flask run --host=0.0.0.0 --port=5000"
echo ""
echo "Or to run in background:"
echo "  nohup python -m flask run --host=0.0.0.0 --port=5000 > flask.log 2>&1 &"
echo ""
echo "To test the team collaboration endpoints:"
echo "  curl -H \"Authorization: Bearer YOUR_TOKEN\" http://127.0.0.1:5000/api/admin/team/members"
echo ""
echo "Environment variables for this session:"
echo "  FLASK_APP=$FLASK_APP"
echo "  FLASK_CONFIG=$FLASK_CONFIG"
echo "  FLASK_DEBUG=$FLASK_DEBUG"
echo ""
echo "Remember to activate the venv in new terminals:"
echo "  source .venv/bin/activate"
echo "=========================================="
