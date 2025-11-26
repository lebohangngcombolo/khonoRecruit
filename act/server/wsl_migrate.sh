#!/bin/bash
# Run this in WSL from /mnt/c/Users/User/Work/khonoRecruit/act/server

echo "==================================="
echo "Team Collaboration Migration Script"
echo "==================================="
echo ""

# Activate venv
source .venv/bin/activate

# Set environment
export FLASK_APP=app:create_app
export FLASK_CONFIG=development
export FLASK_DEBUG=1

# Check current revision
echo "Current database revision:"
python -m flask db current
echo ""

# Show available heads
echo "Available migration heads:"
python -m flask db heads
echo ""

# Apply migrations
echo "Applying migrations..."
python -m flask db upgrade
echo ""

# Show new revision
echo "New database revision:"
python -m flask db current
echo ""

echo "==================================="
echo "✅ Migration Complete!"
echo "==================================="
echo ""
echo "Start the server with:"
echo "  python -m flask run --host=0.0.0.0 --port=5000"
echo ""
