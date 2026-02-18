import asyncio
import os
from collections.abc import AsyncGenerator

import pytest
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

# Set required env vars before app imports
os.environ.setdefault("DATABASE_URL", "postgresql+asyncpg://user:pass@localhost:5432/clair_test")
os.environ.setdefault("FIREBASE_PROJECT_ID", "test-project")

from app.config import settings
from app.database import Base, get_db
from app.main import app


@pytest.fixture(scope="session")
def event_loop():
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


@pytest.fixture
async def async_session() -> AsyncGenerator[AsyncSession, None]:
    engine = create_async_engine(
        settings.DATABASE_URL,
        echo=False,
    )
    async_session_maker = async_sessionmaker(
        engine,
        class_=AsyncSession,
        expire_on_commit=False,
        autocommit=False,
        autoflush=False,
    )

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with async_session_maker() as session:
        yield session

    await engine.dispose()


@pytest.fixture
def override_get_db(async_session: AsyncSession):
    async def _get_db():
        yield async_session

    app.dependency_overrides[get_db] = _get_db
    yield
    app.dependency_overrides.pop(get_db, None)
