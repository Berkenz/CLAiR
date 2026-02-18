from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    DATABASE_URL: str
    FIREBASE_PROJECT_ID: str
    CORS_ORIGINS: list[str] = ["http://localhost:3000"]
    ENVIRONMENT: str = "development"
    DEBUG: bool = False
    APP_NAME: str = "CLAiR API"
    APP_VERSION: str = "0.1.0"


settings = Settings()
