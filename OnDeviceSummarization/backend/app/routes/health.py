# app/routes/health.py
from fastapi import APIRouter, Request
from pathlib import Path
from typing import Any, Dict

router = APIRouter()

def _art_summary(art: Dict[str, Any]):
    if not art:
        return {"loaded": False, "loaded_keys": [], "models_dir": None}
    keys = [k for k, v in art.items() if k != "models_dir" and v is not None]
    return {
        "loaded": bool(len(keys)),
        "loaded_keys": keys,
        "models_dir": str(art.get("models_dir")) if art.get("models_dir") else None
    }

@router.get("/health")
def health(request: Request):
    """
    Health check that reports whether model artifacts were loaded and
    which artifact files were successfully loaded.
    """
    art = getattr(request.app.state, "ART", None)
    summary = _art_summary(art)
    if summary["loaded"]:
        return {
            "status": "model_loaded",
            "model_loaded": True,
            "models_dir": summary["models_dir"],
            "loaded_keys": summary["loaded_keys"],
            "load_error": None
        }
    else:
        # if ART exists but is empty, include the path we attempted
        attempted_dir = None
        if art and art.get("models_dir"):
            attempted_dir = str(art.get("models_dir"))
            # show listing for debugging
            try:
                files = [p.name for p in Path(attempted_dir).iterdir()]
            except Exception:
                files = []
        else:
            attempted_dir = None
            files = []

        return {
            "status": "no_model",
            "model_loaded": False,
            "model_path": attempted_dir,
            "files_present": files,
            "load_error": None
        }
