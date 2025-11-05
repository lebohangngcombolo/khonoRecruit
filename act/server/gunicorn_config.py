import os
import multiprocessing

# Bind to the port provided by Render (defaults to 10000)
bind = "0.0.0.0:" + str(os.environ.get("PORT", 10000))

# Worker configuration
workers = multiprocessing.cpu_count() * 2 + 1  # Recommended formula
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
loglevel = "info"

# Process naming
proc_name = "khonorecruit"

# Server mechanics
daemon = False
pidfile = None
umask = 0
user = None
group = None
tmp_upload_dir = None

# SSL (if needed)
keyfile = None
certfile = None

# Security
limit_request_line = 4096
limit_request_fields = 100
limit_request_field_size = 8190
