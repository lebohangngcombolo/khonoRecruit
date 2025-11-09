# 🚀 Quick Start Guide - Test Suite

## 📁 Test Files Overview

Your test suite includes **7 files** organized for comprehensive testing:

```
tests/
├── README.md                          📖 Full documentation
├── QUICK_START.md                     ⚡ This file
├── requirements_tests.txt             📦 Python dependencies
├── get_jwt_tokens.py                  🔑 Token generator
├── test_hiring_manager_endpoints.py   🧪 API tests (Python)
├── test_database_integrity.sql        💾 Database tests (SQL)
├── run_all_tests.ps1                  🔄 PowerShell runner (recommended)
└── run_tests.cmd                      🪟 Windows CMD runner (simple)
```

---

## ⚡ Quick Start (3 Steps)

### 1️⃣ Install Dependencies
```bash
pip install -r requirements_tests.txt
```

### 2️⃣ Get JWT Tokens
```bash
python get_jwt_tokens.py
```
Enter your hiring manager credentials when prompted.

### 3️⃣ Run Tests

**Option A - Full Suite (PowerShell - Recommended)**:
```powershell
./run_all_tests.ps1
```
Runs API + Database tests, generates report.

**Option B - Quick API Test (CMD)**:
```cmd
run_tests.cmd
```
Runs API tests only, simpler output.

**Option C - Manual Individual Tests**:
```bash
# API tests only
python test_hiring_manager_endpoints.py

# Database tests only
psql -U appuser -d recruitment_db -f test_database_integrity.sql
```

---

## 📋 What Gets Tested?

### ✅ API Tests (30+ checks)
- Access control (9 shared endpoints)
- Admin blocking (4 admin-only endpoints)
- Job CRUD (create, read, update, delete)
- Score calculations (60/40 weighting)
- Interview management
- Team collaboration
- Notifications

### ✅ Database Tests (10 sections)
- Score calculation accuracy
- Data relationships
- Orphaned records
- User role distribution
- Interview scheduling
- Team activity tracking

---

## 📊 Expected Results

### ✅ Success
```
✓ Dashboard Statistics: /dashboard-counts
✓ Job CRUD: Created job ID 42
✓ Score Calculation: All scores accurate
✓ Admin Endpoints: Correctly blocked (403)

TEST EXECUTION SUMMARY
Passed: 23
Failed: 0
Success Rate: 100%

🎉 ALL TESTS PASSED!
```

### ❌ Failure Example
```
✗ Job Creation Failed - Status 400
✗ Score Mismatch - Expected 87.0, Got 85.5

Passed: 18
Failed: 5
Success Rate: 78.3%

⚠️ SOME TESTS FAILED
```

---

## 🔧 Troubleshooting

### "Flask server not running"
```bash
cd c:/Users/User/Work/khonoRecruit/act/server
python run.py
```

### "Invalid token" or "Token expired"
```bash
# Delete old tokens and get new ones
del test_tokens.txt
python get_jwt_tokens.py
```

### "psql not found" (for database tests)
- Install PostgreSQL client
- Or skip database tests (API tests still run)

### "Wrong role" error
Ensure you're using **hiring manager** credentials, not candidate.

---

## 📝 Test Configuration

### JWT Tokens
Tokens are stored in `test_tokens.txt`:
```
HM_TOKEN=eyJ0eXAiOiJKV1QiLCJhbGc...
ADMIN_TOKEN=eyJ0eXAiOiJKV1QiLCJhbGc...  (optional)
```

### Database Connection
Set environment variables (optional):
```powershell
$env:DB_HOST = "localhost"
$env:DB_PORT = "5432"
$env:DB_NAME = "recruitment_db"
$env:DB_USER = "appuser"
$env:DB_PASSWORD = "your_password"
```

---

## 🎯 What to Look For

### ✅ Must Pass
- All API endpoint tests
- All admin endpoints blocked
- Score calculations accurate
- No orphaned database records

### ⚠️ Acceptable Warnings
- No test data (jobs/candidates)
- Database tests skipped (psql not installed)
- Admin token not provided

### ❌ Critical Failures
- Hiring manager can access admin endpoints
- Score calculations incorrect
- CRUD operations failing
- Database orphaned records

---

## 📞 Quick Reference

| Task | Command |
|------|---------|
| **Install deps** | `pip install -r requirements_tests.txt` |
| **Get tokens** | `python get_jwt_tokens.py` |
| **Full test suite** | `./run_all_tests.ps1` |
| **Quick API test** | `run_tests.cmd` or `python test_hiring_manager_endpoints.py` |
| **Database test** | `psql -U appuser -d recruitment_db -f test_database_integrity.sql` |
| **Read docs** | Open `README.md` |

---

## ⏱️ Time Estimates

- **First-time setup**: 5 minutes
- **Get JWT tokens**: 30 seconds
- **API tests**: 20-30 seconds
- **Database tests**: 10-15 seconds
- **Full suite with report**: 1-2 minutes

---

## ✅ Pre-Test Checklist

Before running tests, ensure:
- [ ] Flask server running (`http://127.0.0.1:5000`)
- [ ] PostgreSQL database accessible
- [ ] Python 3.8+ installed
- [ ] `requests` library installed
- [ ] Hiring manager user exists in database
- [ ] Test data available (jobs, candidates, applications)

---

## 🎉 Success Criteria

Your implementation is **production-ready** when:
- ✅ API test pass rate: **100%**
- ✅ Score accuracy: **≥99%**
- ✅ Admin isolation: **All blocked (403)**
- ✅ Database integrity: **No orphans**

---

## 📚 Need More Details?

See [`README.md`](README.md) for:
- Detailed test descriptions
- Troubleshooting guide
- CI/CD integration
- Test coverage breakdown
- Advanced configuration

---

## 🔄 Typical Workflow

```bash
# 1. Start server (if not running)
cd act/server
python run.py

# 2. Open new terminal
cd act/server/tests

# 3. First time? Get tokens
python get_jwt_tokens.py

# 4. Run tests
./run_all_tests.ps1

# 5. Review results
# ✓ All passed? You're production-ready! 🎉
# ✗ Some failed? Check output and fix issues
```

---

## 💡 Pro Tips

1. **Save your tokens** - They're reusable until expired
2. **Run tests after changes** - Catch regressions early
3. **Check database tests** - Reveals data integrity issues
4. **Use PowerShell runner** - Most comprehensive results
5. **Review test reports** - Saved with timestamps

---

## 🆘 Quick Help

**Error**: Cannot connect to server  
**Fix**: Start Flask with `python run.py`

**Error**: Invalid token  
**Fix**: Run `python get_jwt_tokens.py` again

**Error**: Permission denied  
**Fix**: Check database credentials in environment

**Error**: Module not found  
**Fix**: Run `pip install -r requirements_tests.txt`

---

## 📈 What's Next?

After all tests pass:
1. ✅ Review test report
2. ✅ Check admin isolation
3. ✅ Verify score calculations
4. ✅ Deploy with confidence!

**Need help?** See full docs in [`README.md`](README.md)

---

**Ready to test?**
```bash
python get_jwt_tokens.py && ./run_all_tests.ps1
```

**Expected**: 🎉 100% pass rate - Production ready!
