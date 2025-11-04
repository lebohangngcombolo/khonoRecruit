from flask import Flask
from .extensions import (
    db,
    jwt,
    mail,
    cloudinary_client,
    mongo_client,
    migrate,
    cors,
    bcrypt,
    oauth,
)
from .models import *
from .routes import auth, admin_routes, candidate_routes, ai_routes

def create_app():
    app = Flask(__name__)
    app.config.from_object("app.config.Config")

    # ---------------- Initialize Extensions ----------------
    db.init_app(app)
    migrate.init_app(app, db)
    jwt.init_app(app)
    mail.init_app(app)
    oauth.init_app(app)
    bcrypt.init_app(app)
    cloudinary_client.init_app(app)
    cors.init_app(
        app,
        origins=["*"],  # Allow all origins for development; adjust for production
        methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allow_headers=["Content-Type", "Authorization", "X-Requested-With"],
        supports_credentials=True
    )

    # ---------------- Register Blueprints ----------------
    auth.init_auth_routes(app)
    app.register_blueprint(admin_routes.admin_bp, url_prefix="/api/admin")
    app.register_blueprint(candidate_routes.candidate_bp, url_prefix="/api/candidate")
    app.register_blueprint(ai_routes.ai_bp)

    # ---------------- Optional: Auto-create tables (safe) ----------------
    # Only run in dev or if absolutely necessary. Use Flask-Migrate in prod.
    # with app.app_context():
    #     db.create_all()

    return app
