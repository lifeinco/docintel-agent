"""Application settings loaded from environment / .env (ARCHITECTURE.md §11)."""
from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Central configuration. Every field can be overridden via env vars."""

    # --- Database ---
    database_url: str = (
        "postgresql+asyncpg://docintel:docintel@localhost:5432/docintel"
    )

    # --- Auth / JWT ---
    secret_key: str = "change-me-in-production"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    refresh_token_expire_days: int = 30

    # --- Google Cloud ---
    gcs_bucket_name: str = "docintel-documents"
    google_cloud_project: str = "lifeinco-docintel"

    # --- MVP local (fallbacks sin GCP) ---
    seed_demo_data: bool = True
    seed_admin_email: str = "admin@docintel.demo"
    seed_admin_password: str = "DocIntel2026!"
    local_storage_dir: str = "./local_storage"

    # --- Gemini / VertexAI ---
    gemini_api_key: str = ""
    gemini_model_flash: str = "gemini-2.5-flash"
    gemini_model_pro: str = "gemini-2.5-pro"
    vertex_location: str = "us-central1"
    embedding_model: str = "textembedding-gecko@003"

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
