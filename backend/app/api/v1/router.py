from fastapi import APIRouter

from app.api.v1.endpoints import auth, chat, conversations, lawyer_ai_assessment, lawyer_auth, lawyer_profile, users
from app.api.v1.endpoints.appointments import lawyer_router as appt_lawyer_router
from app.api.v1.endpoints.appointments import mobile_router as appt_mobile_router

api_router = APIRouter()

api_router.include_router(auth.router)
api_router.include_router(users.router)
api_router.include_router(chat.router)
api_router.include_router(conversations.router)
api_router.include_router(lawyer_auth.router)
api_router.include_router(lawyer_profile.router)
api_router.include_router(lawyer_ai_assessment.router)
api_router.include_router(appt_mobile_router)
api_router.include_router(appt_lawyer_router)
