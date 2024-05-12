from api.routes import download, health, upload
from api.routes.secured.main import secured_api_router
from fastapi import APIRouter

api_router = APIRouter()
api_router.include_router(health.router, prefix="/health", tags=["Health Routes"])
api_router.include_router(upload.router, prefix="/upload", tags=["Upload Routes"])
api_router.include_router(download.router, prefix="/download", tags=["Download Routes"])
api_router.include_router(secured_api_router)
