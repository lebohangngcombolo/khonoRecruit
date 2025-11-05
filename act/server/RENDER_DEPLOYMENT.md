# 🚀 Render Deployment Guide for khonoRecruit

Complete guide to deploy your khonoRecruit application to Render.

---

## 📋 Prerequisites

- [x] Render account created
- [x] GitHub repository set up
- [x] MongoDB Atlas configured
- [x] Gmail App Password generated
- [x] Cloudinary account ready
- [x] All configuration files created ✅

---

## 🗄️ Step 1: Create PostgreSQL Database

1. **Go to Render Dashboard** → https://dashboard.render.com
2. **Click "New +"** → Select **"PostgreSQL"**
3. **Configure Database:**
   ```
   Name: khonorecruit-db
   Database: recruitment_db
   User: appuser
   Region: Oregon (or closest to you)
   Plan: Starter (Free)
   ```
4. **Click "Create Database"**
5. **Save the Connection String:**
   - Go to the database page
   - Copy the **"Internal Database URL"** (starts with `postgresql://`)
   - Save this for environment variables

---

## 🔴 Step 2: Create Redis Instance

1. **Click "New +"** → Select **"Redis"**
2. **Configure Redis:**
   ```
   Name: khonorecruit-redis
   Region: Oregon (same as PostgreSQL)
   Plan: Starter (Free)
   Maxmemory Policy: allkeys-lru
   ```
3. **Click "Create Redis"**
4. **Save the Connection String:**
   - Copy the **"Internal Redis URL"** (starts with `redis://`)
   - Save this for environment variables

---

## 🌐 Step 3: Create Web Service

1. **Click "New +"** → Select **"Web Service"**
2. **Connect Repository:**
   - Select **"Build and deploy from a Git repository"**
   - Click **"Connect to GitHub"**
   - Select your **khonorecruit** repository
   - Click **"Connect"**

3. **Configure Web Service:**
   ```
   Name: khonorecruit-api
   Region: Oregon (same as databases)
   Branch: main (or your deployment branch)
   Root Directory: act/server
   Runtime: Python 3
   Build Command: bash render-build.sh
   Start Command: gunicorn -c gunicorn_config.py run:app
   Plan: Starter (Free)
   ```

4. **Advanced Settings:**
   - **Auto-Deploy:** Yes (deploys on git push)
   - **Health Check Path:** `/api/health`

---

## ⚙️ Step 4: Configure Environment Variables

In your web service settings, add these environment variables:

### Required Environment Variables

```bash
# Flask Configuration
SECRET_KEY=de596833bc417f52134ab287a5317e357722d52f6e8568b6b44a61d84855e999
JWT_SECRET_KEY=2df86aac1e7c2b13d06b19bf890e90848e989f9bbf71f07d98429448d90c1bf2
FLASK_ENV=production
FLASK_APP=run.py
FLASK_DEBUG=False

# Database URLs (Use Render Internal URLs)
DATABASE_URL=[PASTE YOUR POSTGRESQL INTERNAL URL]
REDIS_URL=[PASTE YOUR REDIS INTERNAL URL]

# MongoDB (Your existing Atlas connection)
MONGO_URI=mongodb+srv://lebohangngcombolo_db_user:vFOmITKu9TMo6h0w@cluster0.al4mvhv.mongodb.net/khonorecruit?retryWrites=true&w=majority

# Email Configuration
MAIL_SERVER=smtp.gmail.com
MAIL_PORT=587
MAIL_USE_TLS=True
MAIL_USERNAME=lebohangngcombolo@gmail.com
MAIL_PASSWORD=vpokqrgldvklywqu

# Cloudinary
CLOUDINARY_CLOUD_NAME=dpu8lnh3o
CLOUDINARY_API_KEY=137431428237442
CLOUDINARY_API_SECRET=6M-fdrK6oEBN0cMLBlhaV0P2zRk

# AI Configuration
OPENROUTER_API_KEY=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

# Frontend URL (Update after frontend deployment)
FRONTEND_URL=https://your-frontend-domain.com
```

### Adding Variables in Render:
1. Go to your web service → **"Environment"** tab
2. Click **"Add Environment Variable"**
3. Enter **Key** and **Value**
4. Click **"Save Changes"**

---

## 🔧 Step 5: Initialize Database Migrations

After first deployment, you need to initialize migrations:

### Option 1: Using Render Shell
1. Go to your web service → **"Shell"** tab
2. Run these commands:
   ```bash
   flask db init
   flask db migrate -m "Initial migration"
   flask db upgrade
   ```

### Option 2: Using render-build.sh (Automatic)
The `render-build.sh` script will automatically run migrations during build.

---

## 🚀 Step 6: Deploy

1. **Click "Create Web Service"**
2. Render will automatically:
   - Clone your repository
   - Run the build script
   - Install dependencies
   - Download spaCy models
   - Run database migrations
   - Start your application

3. **Monitor Deployment:**
   - Watch the **"Logs"** tab
   - Look for: `✅ Build completed successfully!`
   - Then: `Starting gunicorn...`

---

## ✅ Step 7: Verify Deployment

### Check Service Status
- Go to your web service dashboard
- Status should show **"Live"** (green)

### Test Endpoints
```bash
# Replace with your Render URL
RENDER_URL="https://khonorecruit-api.onrender.com"

# Test health check
curl $RENDER_URL/api/health

# Test database connection
curl $RENDER_URL/api/admin/users
```

### Check Logs
- Go to **"Logs"** tab in Render dashboard
- Look for any errors or warnings
- Verify database connections are successful

---

## 🔄 Step 8: Setup Auto-Deploy

Your service is already configured for auto-deploy!

**To deploy updates:**
```bash
git add .
git commit -m "Your changes"
git push origin main
```

Render will automatically detect the push and redeploy.

---

## 🛡️ Step 9: Security Configuration

### 1. Gmail App Password
If using regular Gmail password, create an App Password:
1. Go to **Google Account** → **Security**
2. Enable **2-Step Verification**
3. Go to **App Passwords**
4. Generate password for "Mail"
5. Update `MAIL_PASSWORD` in Render

### 2. MongoDB Atlas Whitelist
1. Go to **MongoDB Atlas** → **Network Access**
2. Add IP: `0.0.0.0/0` (allow all) - for Render
3. Or find Render's outbound IPs and whitelist those

### 3. CORS Configuration
Update in `app/__init__.py` if needed:
```python
cors.init_app(
    app,
    origins=["https://your-frontend-domain.com"],  # Your actual frontend
    methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["Content-Type", "Authorization"],
    supports_credentials=True
)
```

---

## 📊 Step 10: Monitor Your Application

### Render Dashboard
- **Metrics:** CPU, Memory, Bandwidth usage
- **Logs:** Real-time application logs
- **Events:** Deployment history

### Log Viewing
```bash
# In Render dashboard → Logs tab
# Or use Render CLI (if installed)
render logs -s khonorecruit-api --tail
```

---

## 🐛 Troubleshooting

### Build Fails
- Check **Logs** tab for error messages
- Verify `requirements.txt` has all dependencies
- Ensure Python version is compatible (3.11)

### Application Crashes
- Check environment variables are set correctly
- Verify database URLs are correct (use Internal URLs)
- Check `gunicorn_config.py` settings

### Database Connection Issues
- Verify `DATABASE_URL` is the **Internal** URL
- Check PostgreSQL database is in same region
- Ensure database is running (check status)

### Redis Connection Issues
- Verify `REDIS_URL` is correct
- Check Redis instance is running
- Use Internal Redis URL, not External

### Migration Issues
```bash
# In Render Shell
flask db stamp head  # Reset migration state
flask db migrate -m "Fix migrations"
flask db upgrade
```

---

## 🔄 Using Windsurf CLI (Alternative Deployment)

If you prefer using Windsurf:

### Install Windsurf
```bash
npm install -g @windsurf/cli
# or
pip install windsurf
```

### Login to Render
```bash
windsurf login
```

### Deploy
```bash
windsurf deploy --service khonorecruit
```

### Database Migration
```bash
windsurf db:migrate --source local --target render
```

---

## 📝 Important URLs

After deployment, save these URLs:

- **API URL:** `https://khonorecruit-api.onrender.com`
- **PostgreSQL:** Internal URL (from database page)
- **Redis:** Internal URL (from Redis page)
- **Render Dashboard:** https://dashboard.render.com

---

## 🎯 Quick Deployment Checklist

- [ ] PostgreSQL database created
- [ ] Redis instance created
- [ ] Web service created and connected to GitHub
- [ ] All environment variables configured
- [ ] Gmail App Password set
- [ ] MongoDB Atlas whitelist updated
- [ ] First deployment successful
- [ ] Health check passing
- [ ] Database migrations completed
- [ ] API endpoints tested
- [ ] Auto-deploy configured
- [ ] Frontend URL updated (when ready)

---

## 🚨 Next Steps

1. **Test all API endpoints** thoroughly
2. **Deploy your frontend** (separate Render Static Site)
3. **Update CORS** with actual frontend URL
4. **Update FRONTEND_URL** environment variable
5. **Monitor logs** for first few days
6. **Set up monitoring/alerts** (Render provides basic metrics)

---

## 📞 Support

- **Render Documentation:** https://render.com/docs
- **Render Community:** https://community.render.com
- **GitHub Issues:** Create issue in your repository

---

**Your application should now be live on Render! 🎉**

Access it at: `https://khonorecruit-api.onrender.com`
