from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.routers import auth, media, sync
from app.routers.health import router as health_router

settings = get_settings()
Path(settings.media_root).mkdir(parents=True, exist_ok=True)

app = FastAPI(title="PHI Smart App API", version="0.1.0")
origins = ["*"] if settings.cors_origins == "*" else [o.strip() for o in settings.cors_origins.split(",")]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health_router)
app.include_router(auth.router)
app.include_router(sync.router)
app.include_router(media.router)
