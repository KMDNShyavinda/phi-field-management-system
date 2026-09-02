from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str = "postgresql://phi:phi@localhost:5432/phi"
    secret_key: str = "dev-secret-change-me-for-production"
    access_token_minutes: int = 480
    refresh_token_days: int = 30
    media_root: str = "media"
    cors_origins: str = "*"


@lru_cache
def get_settings() -> Settings:
    return Settings()
