import firebase_admin
from firebase_admin import auth, credentials
from fastapi import HTTPException, status

from app.config import settings


def init_firebase() -> None:
    """Initialize Firebase Admin SDK using Application Default Credentials."""
    if not firebase_admin._apps:
        firebase_admin.initialize_app(options={"projectId": settings.FIREBASE_PROJECT_ID})


def verify_firebase_token(token: str) -> dict:
    """
    Verify a Firebase ID token and return the decoded token dict.
    Raises HTTPException 401 on invalid or expired tokens.
    """
    try:
        init_firebase()
        decoded_token = auth.verify_id_token(token)
        return decoded_token
    except auth.InvalidIdTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired Firebase token",
        )
    except auth.ExpiredIdTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Firebase token has expired",
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Token verification failed: {str(e)}",
        )
