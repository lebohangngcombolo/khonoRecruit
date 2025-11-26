"""Quick database check"""
from sqlalchemy import create_engine, inspect, text

DATABASE_URL = "postgresql://appuser:password@localhost/recruitment_db"

try:
    engine = create_engine(DATABASE_URL)
    with engine.connect() as conn:
        # Check if we can connect
        result = conn.execute(text("SELECT version();"))
        print("[OK] Database connection successful!")
        
        # Check tables
        inspector = inspect(engine)
        tables = inspector.get_table_names()
        
        if tables:
            print(f"\n[OK] Found {len(tables)} tables:")
            for table in tables:
                # Count rows
                result = conn.execute(text(f"SELECT COUNT(*) FROM {table}"))
                count = result.scalar()
                print(f"  - {table}: {count} rows")
        else:
            print("\n[!] No tables found - need to run init_db.py")
            
except Exception as e:
    print(f"[ERROR] Database error: {e}")
    print("\nYou need to:")
    print("1. Create the database user and database")
    print("2. Run init_db.py to create tables")
    print("3. Run seed_hiring_manager_data.py to add data")
