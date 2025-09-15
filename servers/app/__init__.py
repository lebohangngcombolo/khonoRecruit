from flask import Flask
from .extensions import db, jwt, mail, redis_client, cloudinary_client, mongo_client,migrate, cors, socketio
from .routes import candidate_routes, job_routes, assessment_routes, admin_routes, auth
from .models import *

def create_app():
    app = Flask(__name__)
    app.config.from_object("app.config.Config")

    # Initialize extensions
    db.init_app(app)
    jwt.init_app(app)
    mail.init_app(app)
    redis_client.init_app(app)
    cloudinary_client.init_app(app)
    migrate.init_app(app, db)
    cors.init_app(app)
    socketio.init_app(app, cors_allowed_origins="*", message_queue=app.config['REDIS_URL'])


    # Register routes
    candidate_routes.init_candidate_routes(app)
    job_routes.init_job_routes(app)
    assessment_routes.init_assessment_routes(app)
    admin_routes.init_admin_routes(app)
    auth.init_auth_routes(app)

    return app
