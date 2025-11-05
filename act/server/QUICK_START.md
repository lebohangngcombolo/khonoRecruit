# 🚀 Quick Start Guide - Render Deployment

Fast-track guide to deploy khonoRecruit to Render in 15 minutes.

---

## 📦 What's Already Done ✅

All deployment files have been created for you:
- ✅ `gunicorn_config.py` - Production server configuration
- ✅ `render-build.sh` - Build and migration script
- ✅ `render.yaml` - Infrastructure as Code config
- ✅ `windsurf.config.json` - Windsurf CLI config
- ✅ `Procfile` - Process file for Render
- ✅ `runtime.txt` - Python version specification
- ✅ `.env.example` - Environment variables template
- ✅ `.gitignore` - Git ignore rules
- ✅ Health check endpoints at `/api/health` and `/api/ping`

---

## 🎯 Deploy in 5 Steps

### 1️⃣ Create Render Services (5 min)

Go to https://dashboard.render.com

**Create PostgreSQL:**
```
New + → PostgreSQL
Name: khonorecruit-db
Region: Oregon
Plan: Starter (Free)
→ Copy Internal URL
```

**Create Redis:**
```
New + → Redis
Name: khonorecruit-redis
Region: Oregon
Plan: Starter (Free)
→ Copy Internal URL
```

---

### 2️⃣ Deploy Web Service (2 min)

```
New + → Web Service
→ Connect GitHub repository
Name: khonorecruit-api
Root Directory: act/server
Build: bash render-build.sh
Start: gunicorn -c gunicorn_config.py run:app
Health Check: /api/health
```

---

### 3️⃣ Add Environment Variables (5 min)

In Web Service → Environment tab, add:

**Critical (Replace URLs!):**
```bash
DATABASE_URL=[YOUR_POSTGRESQL_INTERNAL_URL]
REDIS_URL=[YOUR_REDIS_INTERNAL_URL]
```

**Copy-Paste These:**
```bash
SECRET_KEY=de596833bc417f52134ab287a5317e357722d52f6e8568b6b44a61d84855e999
JWT_SECRET_KEY=2df86aac1e7c2b13d06b19bf890e90848e989f9bbf71f07d98429448d90c1bf2
FLASK_ENV=production
FLASK_APP=run.py
FLASK_DEBUG=False
MONGO_URI=mongodb+srv://lebohangngcombolo_db_user:vFOmITKu9TMo6h0w@cluster0.al4mvhv.mongodb.net/khonorecruit?retryWrites=true&w=majority
MAIL_SERVER=smtp.gmail.com
MAIL_PORT=587
MAIL_USE_TLS=True
MAIL_USERNAME=lebohangngcombolo@gmail.com
MAIL_PASSWORD=vpokqrgldvklywqu
CLOUDINARY_CLOUD_NAME=dpu8lnh3o
CLOUDINARY_API_KEY=137431428237442
CLOUDINARY_API_SECRET=6M-fdrK6oEBN0cMLBlhaV0P2zRk
OPENROUTER_API_KEY=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
FRONTEND_URL=https://your-frontend-domain.com
```

---

### 4️⃣ Deploy (2 min)

Click **"Create Web Service"**

Watch the logs for:
```
✅ Build completed successfully!
Starting gunicorn...
```

---

### 5️⃣ Verify (1 min)

Test your API:
```bash
curl https://your-app.onrender.com/api/health
curl https://your-app.onrender.com/api/ping
```

Should return:
```json
{
  "status": "healthy",
  "service": "khonoRecruit API",
  "checks": {
    "postgresql": "connected",
    "mongodb": "connected",
    "redis": "connected"
  }
}
```

---

## 🎉 You're Live!

Your API is now deployed at:
```
https://khonorecruit-api.onrender.com
```

---

## 🔧 If Something Goes Wrong

### Build Fails?
1. Check Logs tab in Render
2. Verify all files are committed to Git
3. Check Python version compatibility

### Can't Connect to Database?
1. Verify you used **Internal URLs** (not External)
2. Check PostgreSQL database is "Available"
3. Check environment variables are saved

### Health Check Failing?
1. Check environment variables are correct
2. Verify MongoDB Atlas allows connections from 0.0.0.0/0
3. Check all three services (web, db, redis) are running

---

## 📚 Full Documentation

For detailed instructions, see:
- **`RENDER_DEPLOYMENT.md`** - Complete deployment guide
- **`DEPLOYMENT_CHECKLIST.md`** - Step-by-step checklist

---

## 🚀 Next Steps

1. ✅ API deployed
2. 📝 Deploy frontend (separate static site)
3. 🔗 Update CORS with frontend URL
4. 🔐 Generate Gmail App Password (optional)
5. 📊 Monitor logs and metrics

---

## 💡 Pro Tips

**Auto-Deploy:** Every `git push` to main branch auto-deploys!

**View Logs:**
```
Render Dashboard → Your Service → Logs
```

**Database Shell:**
```
Render Dashboard → PostgreSQL → Shell
```

**Web Service Shell:**
```
Render Dashboard → Web Service → Shell
```

**Run Migrations:**
```bash
# In Web Service Shell
flask db upgrade
```

---

## ⚡ Speed Run (For Experts)

```bash
# 1. Render Dashboard: Create PostgreSQL + Redis
# 2. Create Web Service from GitHub
# 3. Set Root: act/server
# 4. Set Build: bash render-build.sh
# 5. Set Start: gunicorn -c gunicorn_config.py run:app
# 6. Paste all env vars
# 7. Deploy!
```

---

**Ready to deploy? Follow the 5 steps above! 🚀**
