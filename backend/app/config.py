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
    # Vertex AI (Google Cloud — bills to GCP credits). Set project + credentials JSON.
    GCP_PROJECT_ID: str | None = None
    GCP_VERTEX_LOCATION: str = "us-central1"
    # Path to service-account JSON (inside container often /app/gcp-vertex-key.json).
    GCP_VERTEX_CREDENTIALS_PATH: str | None = None
    # Standard Google ADC env var (also set in Docker / Render).
    GOOGLE_APPLICATION_CREDENTIALS: str | None = None
    VERTEX_CHAT_MODEL: str = "gemini-2.5-flash"
    VERTEX_TITLE_MODEL: str = "gemini-2.5-flash"
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
    # LLM decides whether to query law_chunks (see rag_router_service.py).
    RAG_ROUTER_ENABLED: bool = True
    GROQ_RAG_ROUTER_MODEL: str = "llama-3.1-8b-instant"
    # After retrieval: drop results when the best vector match is below this (0–1).
    RAG_MIN_TOP_SIMILARITY: float = 0.72
    # How much enactment date affects ranking (lower = trust semantic match more).
    RAG_RECENCY_WEIGHT: float = 0.10
    # Max supreme_court_decisions chunks in top-k unless the query asks for case law.
    RAG_MAX_SC_DECISIONS: int = 1
    # Grade each retrieved excerpt with an LLM before injecting/showing.
    RAG_RELEVANCE_FILTER_ENABLED: bool = True
    RAG_RELEVANCE_FALLBACK_MIN_SIMILARITY: float = 0.80
    # Re-check candidates against the user's message (not expanded query).
    RAG_ORIGINAL_QUERY_MIN_SIMILARITY: float = 0.70
    # When true and the reply cites laws, UI may show cited laws only; verified
    # retrieval is still shown if citation parsing finds nothing.
    RAG_DISPLAY_ONLY_MATCHING: bool = False
    # File storage: supabase (default) or gcs (Google Cloud Storage — uses GCP credits).
    STORAGE_BACKEND: str = "supabase"
    GCS_BUCKET_NAME: str | None = None
    GCS_PROJECT_ID: str | None = None  # defaults to GCP_PROJECT_ID
    SUPABASE_URL: str | None = None
    SUPABASE_SERVICE_ROLE_KEY: str | None = None
    SUPABASE_DB_URL: str | None = None
    EMBED_SERVICE_URL: str | None = None  # e.g. http://your-vm-ip:8001
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
    # Mobile push (FCM) — requires FIREBASE_SERVICE_ACCOUNT_KEY with FCM scope.
    PUSH_NOTIFICATIONS_ENABLED: bool = True
    # Chat abuse protection (see app.core.rate_limit).
    CHAT_RATE_LIMIT_ENABLED: bool = True
    CHAT_RATE_LIMIT_REGISTERED: str = "15/minute"
    CHAT_RATE_LIMIT_ANONYMOUS: str = "5/minute"
    ENVIRONMENT: str = "development"
    DEBUG: bool = False
    APP_NAME: str = "CLAiR API"
    APP_VERSION: str = "0.1.0"


settings = Settings()
