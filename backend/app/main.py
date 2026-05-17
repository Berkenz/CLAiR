import logging
import sys
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address
from starlette.middleware.cors import CORSMiddleware

from app.api.v1.router import api_router
from app.config import settings

_is_dev = settings.ENVIRONMENT == "development" or settings.DEBUG

limiter = Limiter(key_func=get_remote_address)


def _configure_logging() -> None:
    if settings.DEBUG:
        level = logging.DEBUG
    elif _is_dev:
        level = logging.INFO
    else:
        level = logging.WARNING

    if not _is_dev:
        json_fmt = (
            '{"time":"%(asctime)s","level":"%(levelname)s",'
            '"logger":"%(name)s","message":%(message)r}'
        )
        logging.basicConfig(level=level, format=json_fmt, stream=sys.stdout, force=True)
    else:
        logging.basicConfig(
            level=level,
            format="%(asctime)s %(levelname)s %(name)s: %(message)s",
            force=True,
        )


_configure_logging()

_logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    _logger.info("%s v%s started", settings.APP_NAME, settings.APP_VERSION)
    yield


app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    lifespan=lifespan,
    docs_url="/docs" if _is_dev else None,
    redoc_url="/redoc" if _is_dev else None,
    openapi_url="/openapi.json" if _is_dev else None,
)

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

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
    return {"status": "ok"}


@app.get("/")
async def root():
    if _is_dev:
        from fastapi.responses import RedirectResponse
        return RedirectResponse(url="/docs")
    return {"name": settings.APP_NAME, "version": settings.APP_VERSION}
