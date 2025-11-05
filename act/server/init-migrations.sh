#!/usr/bin/env bash
# Initialize Flask-Migrate for the first time

echo "=========================================="
echo "Initializing Database Migrations"
echo "=========================================="

# Check if migrations directory exists
if [ -d "migrations" ]; then
    echo "⚠️  Migrations directory already exists!"
    echo "If you want to reinitialize, delete the migrations folder first."
    read -p "Delete and reinitialize? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
    rm -rf migrations
    echo "✅ Deleted existing migrations"
fi

# Initialize migrations
echo "📦 Initializing Flask-Migrate..."
flask db init

if [ $? -eq 0 ]; then
    echo "✅ Migrations initialized successfully!"
else
    echo "❌ Failed to initialize migrations"
    exit 1
fi

# Create initial migration
echo ""
echo "📝 Creating initial migration..."
flask db migrate -m "Initial migration"

if [ $? -eq 0 ]; then
    echo "✅ Initial migration created!"
else
    echo "❌ Failed to create initial migration"
    exit 1
fi

# Apply migrations
echo ""
echo "⬆️  Applying migrations to database..."
flask db upgrade

if [ $? -eq 0 ]; then
    echo "✅ Migrations applied successfully!"
else
    echo "❌ Failed to apply migrations"
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ Database migrations setup complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Commit the migrations folder to Git"
echo "2. Push to your repository"
echo "3. Deploy to Render"
echo ""
