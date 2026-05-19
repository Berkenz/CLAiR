"""Storage backend selection (no live GCS/Supabase calls)."""

from app.services import storage_service
from app.services.gcs_storage import public_url


def test_use_gcs_flag(monkeypatch):
    monkeypatch.setattr("app.config.settings.STORAGE_BACKEND", "gcs")
    assert storage_service._use_gcs() is True
    monkeypatch.setattr("app.config.settings.STORAGE_BACKEND", "supabase")
    assert storage_service._use_gcs() is False


def test_gcs_public_url(monkeypatch):
    monkeypatch.setattr(
        "app.services.gcs_storage.settings.GCS_BUCKET_NAME",
        "clair-uploads-test",
    )
    url = public_url("profile-photos/user-1.jpg")
    assert url == (
        "https://storage.googleapis.com/clair-uploads-test/profile-photos/user-1.jpg"
    )


def test_gcs_prefix():
    assert storage_service._gcs_prefix("profile-photos") == "profile-photos/"
