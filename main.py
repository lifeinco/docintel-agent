"""DocIntel Agent — FastAPI entrypoint (Cloud Run).

- lifespan creates the tables on startup (Alembic owns real migrations;
  create_all is a dev convenience and a no-op on existing tables).
- CORS open for dev; restrict allow_origins before production.
- AppException subclasses map to their HTTP status automatically.
"""
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

import models  # noqa: F401 — registers every table on Base.metadata
from core.config import settings
from core.database import AsyncSessionLocal, Base, engine
from core.exceptions import AppException
from core.seed import seed_initial_data
from routers import auth, documents, hitl, reports

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s — %(message)s",
)
logger = logging.getLogger("docintel")


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info(
        "Starting DocIntel API (project=%s, bucket=%s)",
        settings.google_cloud_project,
        settings.gcs_bucket_name,
    )
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    await seed_initial_data(AsyncSessionLocal)
    yield
    await engine.dispose()
    logger.info("DocIntel API shut down")


app = FastAPI(
    title="DocIntel Agent API",
    description=(
        "Intelligent Document Processing — Flutter + FastAPI + AlloyDB + "
        "Gemini 1.5 + VertexAI"
    ),
    version="1.0.0",
    lifespan=lifespan,
)

# CORS — allow-all is intentional for the hackathon/dev environment.
# Production: replace with the app's actual origins.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(AppException)
async def app_exception_handler(_: Request, exc: AppException) -> JSONResponse:
    """Maps domain AppException subclasses to their HTTP status."""
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.message},
    )


app.include_router(auth.router)
app.include_router(documents.router)
app.include_router(hitl.router)
app.include_router(reports.router)


@app.get("/health", tags=["health"])
async def health() -> dict:
    return {"status": "ok", "service": "docintel-api", "version": "1.0.0"}
