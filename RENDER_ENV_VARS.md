# 🔐 Render Environment Variables Checklist

## ✅ REQUIRED Variables (Must Set in Render Dashboard)

Go to: **Render Dashboard → Your Service → Environment**

| Variable | Example Value | Notes |
|----------|--------------|-------|
| `DATABASE_URL` | `postgresql://user:pass@host/db` | **Use Internal Database URL from your Render PostgreSQL** |
| `SECRET_KEY` | `your-secret-key-here` | Generate a random string (32+ chars) |
| `JWT_SECRET_KEY` | `your-jwt-secret-here` | Generate a random string (32+ chars) |

### How to Get DATABASE_URL:
1. Go to your PostgreSQL service in Render
2. Copy the **Internal Database URL** (faster than external)
3. Paste as `DATABASE_URL` in your Web Service environment

---

## 📧 Optional Variables (For Full Functionality)

### Email Configuration
```
MAIL_SERVER=smtp.gmail.com
MAIL_PORT=587
MAIL_USE_TLS=True
MAIL_USERNAME=your-email@gmail.com
MAIL_PASSWORD=your-app-password
```

### MongoDB (Document Storage)
```
MONGO_URI=mongodb+srv://username:password@cluster.mongodb.net/dbname
```

### Redis (Caching)
```
REDIS_URL=redis://hostname:port
```

### Cloudinary (File Uploads)
```
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_API_KEY=your-api-key
CLOUDINARY_API_SECRET=your-api-secret
```

### OpenRouter API (AI Features)
```
OPENROUTER_API_KEY=your-openrouter-key
```

---

## 🚀 Quick Setup Commands

### Generate Secret Keys (Run locally):
```bash
python -c "import secrets; print('SECRET_KEY:', secrets.token_urlsafe(32))"
python -c "import secrets; print('JWT_SECRET_KEY:', secrets.token_urlsafe(32))"
```

### Copy these outputs to your Render Environment Variables

---

## 🔍 Verify Environment Variables

The build script will automatically check for required variables and show which are missing.

Check the build logs for:
```
✅ All required environment variables are set!
```

If you see errors, add the missing variables in the Render dashboard.
