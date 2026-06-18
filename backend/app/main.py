import re
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.core.config import settings
from app.api.v1.router import api_router
from app.workers.scheduler import start_scheduler, stop_scheduler

_LOCALHOST_RE = re.compile(r"^http://localhost:\d+$")


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    start_scheduler()
    yield
    # Shutdown
    stop_scheduler()


app = FastAPI(
    title=settings.APP_NAME,
    description="API de la plateforme de coupons de paris sportifs",
    version="1.0.0",
    docs_url="/docs" if not settings.is_production else None,
    redoc_url="/redoc" if not settings.is_production else None,
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins_list,
    # En développement : autorise tous les ports localhost (Flutter web, React, etc.)
    allow_origin_regex=r"http://localhost:\d+" if not settings.is_production else None,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router)


@app.exception_handler(Exception)
async def _cors_safe_exception_handler(request: Request, exc: Exception):
    origin = request.headers.get("origin", "")
    allowed = (
        origin in settings.allowed_origins_list
        or (not settings.is_production and bool(_LOCALHOST_RE.match(origin)))
    )
    headers = {}
    if allowed:
        headers["Access-Control-Allow-Origin"] = origin
        headers["Access-Control-Allow-Credentials"] = "true"
    return JSONResponse(
        status_code=500,
        content={"detail": str(exc)},
        headers=headers,
    )


@app.get("/health", tags=["Health"])
async def health_check():
    return {"status": "ok", "env": settings.APP_ENV}
