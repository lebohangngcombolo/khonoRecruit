# Web Routing Fix - Page Refresh Issue

## Problem
When refreshing the page on any route (other than the home page), the app would redirect to the landing page instead of staying on the current route.

## Root Cause
1. **Missing authentication guard**: GoRouter didn't check if the user was logged in on page refresh
2. **No redirect logic**: Routes didn't restore session state from stored tokens
3. **Server configuration**: Web server wasn't configured to handle client-side routing

## Fixes Applied

### 1. **lib/main.dart** - Added Authentication Guard

#### Changes:
- ✅ Added `redirect` function to GoRouter that checks authentication state
- ✅ Public routes: `/`, `/login`, `/reset-password`, `/oauth-callback`
- ✅ Protected routes: All dashboard and profile routes require authentication
- ✅ Auto-redirect authenticated users to their appropriate dashboard based on role
- ✅ Auto-redirect unauthenticated users to login when accessing protected routes
- ✅ Routes now fallback to stored tokens when query params are empty

#### How it works:
```dart
redirect: (context, state) async {
  final token = await AuthService.getAccessToken();
  final isAuthenticated = token != null && token.isNotEmpty;
  
  // Redirect authenticated users away from public pages
  if (isAuthenticated && isPublicRoute) {
    final userInfo = await AuthService.getUserInfo();
    // Redirect to role-specific dashboard
  }
  
  // Redirect unauthenticated users to login
  if (!isAuthenticated && !isPublicRoute) {
    return '/login';
  }
  
  return null; // Allow navigation
}
```

### 2. **web/index.html** - Set Base Href

#### Changes:
- ✅ Set `<base href="/">` explicitly (was using $FLUTTER_BASE_HREF placeholder)
- ✅ Added route restoration logging for debugging

### 3. **web/.htaccess** - Apache Server Configuration

#### Created new file:
```apache
<IfModule mod_rewrite.c>
  RewriteEngine On
  RewriteCond %{REQUEST_FILENAME} -f [OR]
  RewriteCond %{REQUEST_FILENAME} -d
  RewriteRule ^ - [L]
  RewriteRule ^ index.html [L]
</IfModule>
```

This ensures all routes redirect to `index.html` so Flutter can handle routing.

## Server Configuration (For Different Servers)

### Apache (Already configured with .htaccess)
The `.htaccess` file is already created in `web/` directory.

### Nginx
Add this to your nginx configuration:

```nginx
location / {
  try_files $uri $uri/ /index.html;
}
```

### Firebase Hosting
Create `firebase.json`:

```json
{
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

### Netlify
Create `_redirects` file in `web/` directory:

```
/*    /index.html   200
```

### Python HTTP Server (Development)
When running with Python's HTTP server, use:

```bash
python -m http.server 8000
```

Then manually ensure refresh works by configuring your IDE's dev server.

### Flutter Web Dev Server
The Flutter development server (`flutter run -d chrome`) already handles routing correctly.

## Testing the Fix

1. **Build the app**:
   ```bash
   cd khono_recruite
   flutter build web
   ```

2. **Serve locally** (choose one):
   
   **Option A: Python**
   ```bash
   cd build/web
   python -m http.server 8000
   ```
   
   **Option B: Flutter dev server**
   ```bash
   flutter run -d chrome
   ```

3. **Test scenarios**:
   - ✅ Login as a user
   - ✅ Navigate to different pages (dashboard, analytics, etc.)
   - ✅ Refresh the page (F5 or Ctrl+R)
   - ✅ You should stay on the same page, not redirect to landing page
   - ✅ Close the browser and reopen to the URL - should restore session
   - ✅ Logout and try accessing a protected route - should redirect to login

## How Session Persistence Works

1. **Login**: 
   - User logs in → Token stored in `FlutterSecureStorage`
   - User info stored in `SharedPreferences`

2. **Page Refresh**:
   - GoRouter's `redirect` function runs
   - Checks for stored token via `AuthService.getAccessToken()`
   - If token exists, allows access to protected routes
   - If no token, redirects to login

3. **Route Builders**:
   - Each protected route now checks for stored token
   - Falls back to stored token if query parameter is empty
   - Passes token to page widget

## Files Modified

1. ✅ `lib/main.dart` - Added redirect logic and token fallback
2. ✅ `web/index.html` - Set base href to "/"
3. ✅ `web/.htaccess` - Created for Apache server support

## Files Created

1. ✅ `web/.htaccess` - Server rewrite rules for Apache

## Dependencies

All required dependencies already exist:
- `go_router: ^16.2.4` - For routing
- `flutter_secure_storage: ^9.0.0` - For token storage
- `shared_preferences: ^2.2.2` - For user info storage
- `flutter_web_plugins` - For URL strategy

No new dependencies needed!

## Troubleshooting

### Issue: Still redirecting to landing page after refresh
**Solution**: 
- Clear browser cache and stored data
- Check browser console for errors
- Verify token is being stored (check Application > Local Storage in DevTools)

### Issue: "Access token not found" errors
**Solution**:
- Login again to refresh the token
- Check if `FlutterSecureStorage` is working (some browsers block it)
- Try using a different browser

### Issue: Works in development but not in production
**Solution**:
- Ensure server is configured with proper rewrite rules (see Server Configuration above)
- Verify `base href` is set to "/" in production build
- Check if assets are loading correctly

### Issue: Token expires and user stays logged in
**Solution**:
- The current fix preserves sessions indefinitely
- To add token expiration checks, update the `redirect` function to validate token with backend
- Add token refresh logic in `AuthService`

## Future Enhancements (Optional)

1. **Token Validation**: Call backend to verify token is still valid
2. **Token Refresh**: Automatically refresh expired tokens
3. **Remember Me**: Add option to persist login or require re-login
4. **Session Timeout**: Auto-logout after inactivity period

## Notes

- The fix uses `async` redirect which is supported in `go_router` v6+
- Path-based URL strategy is enabled (no # in URLs)
- All routes maintain authentication state across refreshes
- Server-side configuration is required for production deployment
