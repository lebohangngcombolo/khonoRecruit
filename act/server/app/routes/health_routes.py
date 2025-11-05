from flask import Blueprint, jsonify
from app.extensions import db, mongo_client
import redis
import os

health_bp = Blueprint('health', __name__)

@health_bp.route('/api/health', methods=['GET'])
def health_check():
    """
    Health check endpoint for Render and monitoring services.
    Returns the status of the application and its dependencies.
    """
    health_status = {
        'status': 'healthy',
        'service': 'khonoRecruit API',
        'checks': {}
    }
    
    try:
        # Check PostgreSQL connection
        db.session.execute(db.text('SELECT 1'))
        health_status['checks']['postgresql'] = 'connected'
    except Exception as e:
        health_status['checks']['postgresql'] = f'error: {str(e)}'
        health_status['status'] = 'degraded'
    
    try:
        # Check MongoDB connection
        mongo_client.db.command('ping')
        health_status['checks']['mongodb'] = 'connected'
    except Exception as e:
        health_status['checks']['mongodb'] = f'error: {str(e)}'
        health_status['status'] = 'degraded'
    
    try:
        # Check Redis connection (if configured)
        redis_url = os.getenv('REDIS_URL')
        if redis_url:
            redis_client = redis.from_url(redis_url)
            redis_client.ping()
            health_status['checks']['redis'] = 'connected'
        else:
            health_status['checks']['redis'] = 'not configured'
    except Exception as e:
        health_status['checks']['redis'] = f'error: {str(e)}'
        health_status['status'] = 'degraded'
    
    # Return 200 for healthy, 503 for unhealthy
    status_code = 200 if health_status['status'] == 'healthy' else 503
    
    return jsonify(health_status), status_code

@health_bp.route('/api/ping', methods=['GET'])
def ping():
    """Simple ping endpoint for quick availability checks."""
    return jsonify({'status': 'pong'}), 200
