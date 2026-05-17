import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.responses import RedirectResponse
from starlette.middleware.cors import CORSMiddleware

from app.api.v1.router import api_router
from app.config import settings


def _configure_logging() -> None:
    """App loggers default to WARNING; enable INFO in dev so LLM/Tavily lines appear."""
    if settings.DEBUG:
        level = logging.DEBUG
    elif settings.ENVIRONMENT == "development":
        level = logging.INFO
    else:
        level = logging.WARNING

    logging.basicConfig(
        level=level,
        format="%(levelname)s %(name)s: %(message)s",
        force=True,
    )


_configure_logging()


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    print(f"{settings.APP_NAME} v{settings.APP_VERSION} started")
    yield
    # Shutdown
    pass


app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix="/api/v1")


@app.api_route("/health", methods=["GET", "HEAD"])
async def health_check():
    """Health check endpoint."""
    return {"status": "ok"}


@app.get("/")
async def root():
    """Root endpoint - redirects to /docs."""
    return RedirectResponse(url="/docs")
