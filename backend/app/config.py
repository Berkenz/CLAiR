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
    OPENROUTER_API_KEY: str | None = None
    # Primary chat model (Groq).
    GROQ_CHAT_MODEL: str = "llama-3.3-70b-versatile"
    GROQ_TITLE_MODEL: str = "llama-3.1-8b-instant"
    # Fallback 1 — Google AI Studio (Gemini 3.1 Flash-Lite).
    GEMINI_CHAT_MODEL: str = "gemini-3.1-flash-lite"
    GEMINI_TITLE_MODEL: str = "gemini-3.1-flash-lite"
    # Fallback 2 — OpenRouter (openrouter/free routes to an available free model).
    OPENROUTER_CHAT_MODEL: str = "openrouter/free"
    OPENROUTER_TITLE_MODEL: str = "openrouter/free"
    OPENROUTER_HTTP_REFERER: str = "https://clair.local"
    # Chat latency tuning (see chat_service / tavily_service).
    CHAT_MAX_TOKENS: int = 768
    CHAT_USE_FAST_MODEL_FOR_SHORT: bool = True
    GROQ_FAST_CHAT_MODEL: str = "llama-3.1-8b-instant"
    CHAT_FAST_MODEL_MAX_CHARS: int = 200
    CHAT_FAST_MODEL_MAX_HISTORY: int = 4
    TAVILY_TIMEOUT_SECONDS: float = 2.5
    LAWYER_DIRECTORY_CACHE_TTL_SECONDS: int = 300
    CHAT_ALIGN_RAG_SOURCES: bool = True
    SUPABASE_URL: str | None = None
    SUPABASE_SERVICE_ROLE_KEY: str | None = None
    SUPABASE_DB_URL: str | None = None
    EMBED_SERVICE_URL: str | None = None  # e.g. http://34.143.181.61:8001
    TAVILY_API_KEY: str | None = None
    # SMTP — used for sending report notification emails
    SMTP_HOST: str = "smtp.gmail.com"
    SMTP_PORT: int = 587
    SMTP_USER: str | None = None
    SMTP_PASSWORD: str | None = None
    SMTP_FROM_EMAIL: str = "noreply@clair-ai.app"
    REPORT_RECIPIENT_EMAIL: str = "support@clair-ai.app"
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
