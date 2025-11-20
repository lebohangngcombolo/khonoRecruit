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
<<<<<<< HEAD
import os
import json
from dotenv import load_dotenv
import firebase_admin
from firebase_admin import credentials, auth
from flask_bcrypt import Bcrypt

load_dotenv()
=======
import firebase_admin
from firebase_admin import credentials, auth
from flask_bcrypt import Bcrypt
>>>>>>> 75016d5ebef202b71a7cc69eab1f3a3c6c746981

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

<<<<<<< HEAD
firebase_app = None
_cred = None
_sa_json = os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON")
if _sa_json:
    try:
        _cred = credentials.Certificate(json.loads(_sa_json))
    except Exception:
        _cred = None
if _cred is None:
    _path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS") or os.getenv("FIREBASE_CREDENTIALS")
    if _path and os.path.exists(_path):
        _cred = credentials.Certificate(_path)
if _cred is None:
    _default_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "serviceAccountKey.json")
    if os.path.exists(_default_path):
        _cred = credentials.Certificate(_default_path)
if _cred:
    firebase_app = firebase_admin.initialize_app(_cred)
=======
cred = credentials.Certificate("serviceAccountKey.json")  # download from Firebase console
firebase_admin.initialize_app(cred)
>>>>>>> 75016d5ebef202b71a7cc69eab1f3a3c6c746981

# ------------------- Redis Client -------------------
redis_client = redis.Redis(
    host='localhost',  # update if using a different host
    port=6379,         # default Redis port
    db=0,
    decode_responses=True  # makes Redis return strings instead of bytes
)




