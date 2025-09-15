from flask_sqlalchemy import SQLAlchemy
from flask_jwt_extended import JWTManager
from flask_mail import Mail
import redis
import cloudinary
from pymongo import MongoClient
from flask_migrate import Migrate
from flask_cors import CORS
from flask_socketio import SocketIO


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

# Cloudinary config
class CloudinaryClient:
    def init_app(self, app):
        cloudinary.config(
            cloud_name=app.config['CLOUDINARY_CLOUD_NAME'],
            api_key=app.config['CLOUDINARY_API_KEY'],
            api_secret=app.config['CLOUDINARY_API_SECRET']
        )
    def upload(self, file_path):
        return cloudinary.uploader.upload(file_path)

cloudinary_client = CloudinaryClient()

mongo_client = MongoClient('mongodb://localhost:27017/')
mongo_db = mongo_client['recruitment_cv']
