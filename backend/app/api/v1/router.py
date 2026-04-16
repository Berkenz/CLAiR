from fastapi import APIRouter

from app.api.v1.endpoints import auth, chat, conversations, lawyer_auth, lawyer_profile, users

api_router = APIRouter()

api_router.include_router(auth.router)
api_router.include_router(users.router)
api_router.include_router(chat.router)
api_router.include_router(conversations.router)
api_router.include_router(lawyer_auth.router)
api_router.include_router(lawyer_profile.router)
