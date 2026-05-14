from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    DATABASE_URL: str
    FIREBASE_PROJECT_ID: str
    FIREBASE_SERVICE_ACCOUNT_KEY: str | None = None
    FIREBASE_WEB_API_KEY: str | None = None
    GEMINI_API_KEY: str | None = None
    GROQ_API_KEY: str | None = None
    SUPABASE_URL: str | None = None
    SUPABASE_SERVICE_ROLE_KEY: str | None = None
    SUPABASE_DB_URL: str | None = None
    EMBED_SERVICE_URL: str | None = None  # e.g. http://34.143.181.61:8001
    TAVILY_API_KEY: str | None = None
    # Lawyer portal (Vite) runs on 5173; include 127.0.0.1 — browsers treat it separately from localhost.
    CORS_ORIGINS: list[str] = [
        "http://localhost:3000",
        "http://localhost:5173",
        "http://127.0.0.1:5173",
    ]
    ENVIRONMENT: str = "development"
    DEBUG: bool = False
    APP_NAME: str = "CLAiR API"
    APP_VERSION: str = "0.1.0"


settings = Settings()
