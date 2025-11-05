# 🚀 Render Deployment Checklist

Quick reference checklist for deploying khonoRecruit to Render.

---

## ✅ Pre-Deployment Setup

### 1. Local Environment
- [ ] All code changes committed to Git
- [ ] Tests passing locally
- [ ] `.env` configured with production values
- [ ] Database migrations created and tested
- [ ] Requirements.txt up to date

### 2. External Services Ready
- [ ] MongoDB Atlas whitelist configured (0.0.0.0/0 or specific IPs)
- [ ] Gmail App Password generated and saved
- [ ] Cloudinary credentials ready
- [ ] OpenRouter API key active

---

## 🗄️ Render Services Setup

### Step 1: PostgreSQL Database
- [ ] Navigate to https://dashboard.render.com
- [ ] Click "New +" → PostgreSQL
- [ ] Configure:
  - Name: `khonorecruit-db`
  - Database: `recruitment_db`
  - User: `appuser`
  - Region: Oregon (or preferred)
  - Plan: Starter (Free)
- [ ] Copy Internal Database URL and save

### Step 2: Redis Instance
- [ ] Click "New +" → Redis
- [ ] Configure:
  - Name: `khonorecruit-redis`
  - Region: Oregon (same as PostgreSQL)
  - Plan: Starter (Free)
  - Maxmemory Policy: `allkeys-lru`
- [ ] Copy Internal Redis URL and save

### Step 3: Web Service
- [ ] Click "New +" → Web Service
- [ ] Connect GitHub repository
- [ ] Configure:
  - Name: `khonorecruit-api`
  - Region: Oregon
  - Branch: `main`
  - Root Directory: `act/server`
  - Runtime: Python 3
  - Build Command: `bash render-build.sh`
  - Start Command: `gunicorn -c gunicorn_config.py run:app`
  - Plan: Starter (Free)
- [ ] Set Health Check Path: `/api/health`
- [ ] Enable Auto-Deploy

---

## ⚙️ Environment Variables

Copy these to Render Environment Variables section:

### Flask & Security
```
SECRET_KEY=de596833bc417f52134ab287a5317e357722d52f6e8568b6b44a61d84855e999
JWT_SECRET_KEY=2df86aac1e7c2b13d06b19bf890e90848e989f9bbf71f07d98429448d90c1bf2
FLASK_ENV=production
FLASK_APP=run.py
FLASK_DEBUG=False
```

### Databases (Replace with your Render URLs)
```
DATABASE_URL=[YOUR_POSTGRESQL_INTERNAL_URL]
REDIS_URL=[YOUR_REDIS_INTERNAL_URL]
MONGO_URI=mongodb+srv://lebohangngcombolo_db_user:vFOmITKu9TMo6h0w@cluster0.al4mvhv.mongodb.net/khonorecruit?retryWrites=true&w=majority
```

### Email
```
MAIL_SERVER=smtp.gmail.com
MAIL_PORT=587
MAIL_USE_TLS=True
MAIL_USERNAME=lebohangngcombolo@gmail.com
MAIL_PASSWORD=vpokqrgldvklywqu
```

### Cloudinary
```
CLOUDINARY_CLOUD_NAME=dpu8lnh3o
CLOUDINARY_API_KEY=137431428237442
CLOUDINARY_API_SECRET=6M-fdrK6oEBN0cMLBlhaV0P2zRk
```

### AI & Frontend
```
OPENROUTER_API_KEY=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
FRONTEND_URL=https://your-frontend-domain.com
```

- [ ] All environment variables added
- [ ] Database URLs use Internal URLs (not External)
- [ ] Saved changes in Render

---

## 🚀 Deploy & Verify

### Deploy
- [ ] Click "Create Web Service"
- [ ] Monitor deployment in Logs tab
- [ ] Wait for "Build completed successfully!"
- [ ] Wait for "Starting gunicorn..."
- [ ] Service status shows "Live" (green)

### Post-Deployment Verification
- [ ] Health check passing: `https://your-app.onrender.com/api/health`
- [ ] Ping endpoint working: `https://your-app.onrender.com/api/ping`
- [ ] API responding correctly
- [ ] Database connections successful
- [ ] No errors in logs

### Test Key Endpoints
```bash
# Replace with your actual Render URL
export API_URL="https://khonorecruit-api.onrender.com"

# Health check
curl $API_URL/api/health

# Ping
curl $API_URL/api/ping

# Test an actual endpoint (adjust as needed)
curl $API_URL/api/admin/users
```

---

## 🔧 Database Migrations

If migrations didn't run automatically:

- [ ] Go to web service → Shell tab
- [ ] Run migration commands:
  ```bash
  flask db init
  flask db migrate -m "Initial migration"
  flask db upgrade
  ```
- [ ] Verify migrations completed successfully
- [ ] Check database has tables

---

## 🛡️ Security Configuration

### Gmail App Password
- [ ] Google Account → Security
- [ ] Enable 2-Step Verification
- [ ] Generate App Password
- [ ] Update `MAIL_PASSWORD` in Render

### MongoDB Atlas
- [ ] Network Access → Add IP Address
- [ ] Add `0.0.0.0/0` (or Render IPs)
- [ ] Verify connection works

### CORS (Optional - for production)
- [ ] Update `app/__init__.py` with actual frontend domain
- [ ] Replace `origins=["*"]` with your domain
- [ ] Redeploy

---

## 📊 Post-Deployment Tasks

### Monitoring
- [ ] Bookmark Render dashboard
- [ ] Check metrics (CPU, Memory, Bandwidth)
- [ ] Set up any custom alerts
- [ ] Monitor logs for errors

### Documentation
- [ ] Save your Render URLs
- [ ] Document environment variables
- [ ] Update project README with deployment info
- [ ] Share API URL with team/frontend

### Frontend Integration
- [ ] Deploy frontend (if not done)
- [ ] Update `FRONTEND_URL` environment variable
- [ ] Update CORS settings with frontend domain
- [ ] Test frontend → backend integration

---

## 🐛 Common Issues & Solutions

### Build Fails
- **Issue:** Dependencies installation fails
- **Solution:** Check `requirements.txt` syntax, verify all packages exist

### Application Doesn't Start
- **Issue:** Gunicorn can't find app
- **Solution:** Verify `FLASK_APP=run.py` is set, check `run.py` exists

### Database Connection Error
- **Issue:** Can't connect to PostgreSQL
- **Solution:** Use Internal URL, verify region matches, check database is running

### Redis Connection Error
- **Issue:** Redis not connecting
- **Solution:** Verify Internal Redis URL, check Redis instance is live

### Health Check Failing
- **Issue:** `/api/health` returns 503
- **Solution:** Check logs, verify database connections, check environment variables

---

## 🔄 Auto-Deploy Setup

Your deployment is configured for auto-deploy:

### To Deploy Updates:
```bash
# Make changes
git add .
git commit -m "Description of changes"
git push origin main
```

Render will automatically:
1. Detect the push
2. Run build script
3. Install dependencies
4. Run migrations
5. Restart service

Monitor in Render Logs tab!

---

## 📝 Important URLs

Save these after deployment:

- **API URL:** `https://khonorecruit-api.onrender.com`
- **Health Check:** `https://khonorecruit-api.onrender.com/api/health`
- **Render Dashboard:** https://dashboard.render.com
- **PostgreSQL Dashboard:** [Link from Render]
- **Redis Dashboard:** [Link from Render]

---

## ✨ You're Done!

Your khonoRecruit API is now live on Render! 🎉

Next steps:
1. Deploy your frontend
2. Update CORS and FRONTEND_URL
3. Test thoroughly
4. Monitor for any issues
5. Celebrate! 🚀
