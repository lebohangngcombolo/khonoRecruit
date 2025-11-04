import cloudinary
import cloudinary.uploader
from flask_sqlalchemy import SQLAlchemy
from flask_jwt_extended import JWTManager
from flask_mail import Mail
from flask_migrate import Migrate
from flask_cors import CORS
from pymongo import MongoClient
from authlib.integrations.flask_client import OAuth  # <-- updated
import redis
import firebase_admin
from flask_socketio import SocketIO
from flask_bcrypt import Bcrypt

# ------------------- Flask Extensions -------------------
db = SQLAlchemy()
jwt = JWTManager()
mail = Mail()
migrate = Migrate()
oauth = OAuth()  # <-- Authlib OAuth
cors = CORS()

bcrypt = Bcrypt()

# ------------------- Cloudinary Client -------------------
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

# ------------------- MongoDB Client -------------------
mongo_client = MongoClient('mongodb://localhost:27017/')
mongo_db = mongo_client['recruitment_cv']


# ------------------- Redis Client -------------------
redis_client = redis.Redis(
    host='localhost',  # update if using a different host
    port=6379,         # default Redis port
    db=0,
    decode_responses=True  # makes Redis return strings instead of bytes
)




