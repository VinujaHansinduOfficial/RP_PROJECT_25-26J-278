from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import logging
from app.model_utils import load_artifacts

# routers
from app.routes.predict import router as predict_router
from app.routes.health import router as health_router
from app.routes.mental_state import router as mental_state_router
from app.routes.mental_single import router as mental_single_router


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


    @app.on_event("startup")
    def startup_event():
        logger.info("Loading model artifacts at startup...")
        try:
            ART = load_artifacts()
            app.state.ART = ART
            logger.info("Artifacts loaded. models_dir=%s", ART.get("models_dir"))
        except Exception as e:
            app.state.ART = None
            logger.exception("Failed loading artifacts: %s", e)

    return app


app = create_app()
