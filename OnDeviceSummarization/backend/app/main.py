from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import logging
from app.model_utils import load_artifacts

# routers
from app.routes.predict import router as predict_router
from app.routes.health import router as health_router
from app.routes.mental_state import router as mental_state_router
from app.routes.mental_single import router as mental_single_router
from app.routes.auth import router as auth_router
from app.routes.landing import router as landing_router
from app.routes.user_features import router as user_features_router


from pymongo import MongoClient
import os
from dotenv import load_dotenv

load_dotenv()

logger = logging.getLogger("uvicorn.error")


def create_app() -> FastAPI:
    app = FastAPI(
        title="Overstimulation Predictor API",
        version="1.0",
        description="Predict Overstimulated (0/1) using trained RandomForest model."
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(health_router, prefix="", tags=["health"])
    app.include_router(predict_router, prefix="", tags=["prediction"])
    app.include_router(mental_state_router, prefix="", tags=["mental-state"])
    app.include_router(mental_single_router, prefix="", tags=["mental-single"])
    app.include_router(auth_router, prefix="/auth", tags=["auth"])
    app.include_router(landing_router, prefix="/landing", tags=["landing"])
    app.include_router(user_features_router, prefix="", tags=["user-features"])

    @app.on_event("startup")
    def startup_event():
        logger.info("Loading model artifacts at startup...")

        # -----------------------------
        # Load Model Artifacts
        # -----------------------------
        try:
            ART = load_artifacts()
            app.state.ART = ART
            logger.info("Artifacts loaded. models_dir=%s", ART.get("models_dir"))
        except Exception as e:
            app.state.ART = None
            logger.exception("Failed loading artifacts: %s", e)

        # -----------------------------
        # MongoDB Setup (SAFE VERSION)
        # -----------------------------
        try:
            MONGO_URL = os.getenv("MONGO_URL")

            if not MONGO_URL:
                raise Exception("MONGO_URL not found in environment.")

            client = MongoClient(MONGO_URL)

            db = client.get_default_database()


            app.state.db = db
            app.state.col_overstim = db["overstim_predictions"]
            app.state.col_mental_single = db["mental_single_predictions"]

            # Create indexes (important for performance)
            app.state.col_overstim.create_index("user_id")
            app.state.col_mental_single.create_index([("user_id", 1), ("target", 1)])
            app.state.col_users = db["users"]
            app.state.col_sessions = db["sessions"]  # for upcoming sessions
            app.state.col_user_features = db["user_features"]

            # Indexes
            app.state.col_users.create_index("email", unique=True)
            app.state.col_sessions.create_index("user_id")
            app.state.col_user_features.create_index("user_id", unique=True)

            logger.info("MongoDB connected successfully.")

        except Exception as e:
            logger.exception("MongoDB connection failed: %s", e)
            app.state.db = None

    return app



app = create_app()
