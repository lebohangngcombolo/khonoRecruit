import os

# Bind to the port provided by Render environment variable
bind = "0.0.0.0:" + str(os.environ.get("PORT", "10000"))

# Worker configuration - MINIMIZED for 512MB free tier
workers = 1  # Single worker to minimize memory
worker_class = "sync"  # Sync worker uses less memory than gthread
# No threads setting for sync worker

# Timeout configuration
timeout = 120  # Allow time for AI processing
graceful_timeout = 30
keepalive = 2

# Restart workers periodically to prevent memory leaks
max_requests = 500
max_requests_jitter = 50

# Logging
accesslog = "-"  # Log to stdout
errorlog = "-"   # Log to stderr
loglevel = "info"  # Changed back to info for production
capture_output = True

# Process naming
proc_name = "khonorecruit"

# Server mechanics
daemon = False
preload_app = False  # Disabled to reduce memory footprint

# SSL (if needed)
keyfile = None
certfile = None

# Security
limit_request_line = 4096
limit_request_fields = 100
limit_request_field_size = 8190
