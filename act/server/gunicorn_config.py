import os
import multiprocessing

# Bind to the port provided by Render (defaults to 10000)
bind = "0.0.0.0:" + str(os.environ.get("PORT", 10000))

# Worker configuration (optimized for Render Free tier: 512MB RAM)
workers = 2  # Reduced for free tier
worker_class = "gthread"
threads = 2
worker_connections = 1000

# Timeout and restart configuration
timeout = 120  # Increased for AI processing tasks
graceful_timeout = 120
keepalive = 5

# Restart workers after this many requests (helps prevent memory leaks)
max_requests = 1000
max_requests_jitter = 100

# Logging
accesslog = "-"  # Log to stdout
errorlog = "-"   # Log to stderr
loglevel = "debug"  # Changed to debug for troubleshooting
capture_output = True  # Capture stdout/stderr from app

# Process naming
proc_name = "khonorecruit"

# Server mechanics
daemon = False
pidfile = None
umask = 0
user = None
group = None
tmp_upload_dir = None
preload_app = True  # Load app before forking to catch import errors

# SSL (if needed)
keyfile = None
certfile = None

# Security
limit_request_line = 4096
limit_request_fields = 100
limit_request_field_size = 8190
