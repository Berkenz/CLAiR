from datetime import datetime, timezone

from app.schemas.user import UserResponse
from app.utils.photo_url import photo_url_strip_cache_bust, photo_url_with_cache_bust


def test_strip_cache_bust_removes_v_only():
    url = "https://cdn.example.com/u.jpg?v=111&foo=bar"
    assert photo_url_strip_cache_bust(url) == "https://cdn.example.com/u.jpg?foo=bar"


def test_cache_bust_uses_updated_at():
    updated = datetime(2026, 5, 22, 12, 0, 0, tzinfo=timezone.utc)
    url = "https://cdn.example.com/u.jpg"
    busted = photo_url_with_cache_bust(url, updated)
    assert busted is not None
    assert busted.endswith(f"v={int(updated.timestamp() * 1000)}")


def test_user_response_busts_photo_from_updated_at():
    updated = datetime(2026, 5, 22, 12, 0, 0, tzinfo=timezone.utc)
    user = UserResponse(
        id="00000000-0000-0000-0000-000000000001",
        firebase_uid="fb1",
        photo_url="https://cdn.example.com/u.jpg?v=old",
        auth_provider="email",
        is_email_verified=True,
        is_anonymous=False,
        is_active=True,
        created_at=updated,
        updated_at=updated,
    )
    assert user.photo_url is not None
    assert "v=old" not in user.photo_url
    assert user.photo_url.endswith(f"v={int(updated.timestamp() * 1000)}")
