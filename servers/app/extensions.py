import cloudinary
import cloudinary.uploader
from flask_sqlalchemy import SQLAlchemy
from flask_jwt_extended import JWTManager
from flask_mail import Mail
from flask_migrate import Migrate
from flask_cors import CORS
from flask_socketio import SocketIO
import redis
from pymongo import MongoClient

db = SQLAlchemy()
jwt = JWTManager()
mail = Mail()
migrate = Migrate()
cors = CORS()
socketio = SocketIO(async_mode='threading')

# Redis client
class RedisClient:
    def init_app(self, app):
        self.client = redis.Redis(host='localhost', port=6379, db=0)
    def get(self, key):
        return self.client.get(key)
    def setex(self, key, ttl, value):
        self.client.setex(key, ttl, value)

redis_client = RedisClient()

# Cloudinary client
class CloudinaryClient:
    def init_app(self, app):
        cloudinary.config(
            cloud_name=app.config['CLOUDINARY_CLOUD_NAME'],
            api_key=app.config['CLOUDINARY_API_KEY'],
            api_secret=app.config['CLOUDINARY_API_SECRET'],
            secure=True
        )
    def upload(self, file_path):
        try:
            return cloudinary.uploader.upload(file_path)
        except Exception as e:
            raise Exception(f"Cloudinary upload failed: {str(e)}")

cloudinary_client = CloudinaryClient()

# MongoDB client
mongo_client = MongoClient('mongodb://localhost:27017/')
mongo_db = mongo_client['recruitment_cv']

