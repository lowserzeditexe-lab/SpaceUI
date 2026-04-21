from fastapi import FastAPI, APIRouter
from fastapi.responses import Response
from dotenv import load_dotenv
from starlette.middleware.cors import CORSMiddleware
from motor.motor_asyncio import AsyncIOMotorClient
import os
import logging
from pathlib import Path


ROOT_DIR = Path(__file__).parent
load_dotenv(ROOT_DIR / '.env')

# MongoDB connection
mongo_url = os.environ['MONGO_URL']
client = AsyncIOMotorClient(mongo_url)
db = client[os.environ['DB_NAME']]

# Create the main app without a prefix
app = FastAPI(title="SpaceUI", docs_url="/api/docs", openapi_url="/api/openapi.json")

# Create a router with the /api prefix
api_router = APIRouter(prefix="/api")


@api_router.get("/")
async def root():
    return {"message": "SpaceUI backend"}


@api_router.get("/health")
async def health():
    return {"status": "ok", "service": "spaceui"}


# Placeholder Lua library content — Phase 2 will replace with the real library.
SPACEUI_LUA = """-- SpaceUI v0.1 (Phase 2 will implement this)
return {}
"""


@app.get("/spaceui.lua")
async def spaceui_lua():
    # Served OUTSIDE /api so the loadstring URL is clean.
    # Roblox HttpGet needs open CORS.
    return Response(
        content=SPACEUI_LUA,
        media_type="text/plain; charset=utf-8",
        headers={
            "Access-Control-Allow-Origin": "*",
            "Cache-Control": "no-cache",
        },
    )


# Also serve via /api prefix for Kubernetes ingress routing
@api_router.get("/spaceui.lua")
async def spaceui_lua_api():
    """Alias for /spaceui.lua accessible via /api prefix for K8s ingress."""
    return Response(
        content=SPACEUI_LUA,
        media_type="text/plain; charset=utf-8",
        headers={
            "Access-Control-Allow-Origin": "*",
            "Cache-Control": "no-cache",
        },
    )


# Include the router in the main app
app.include_router(api_router)

app.add_middleware(
    CORSMiddleware,
    allow_credentials=True,
    allow_origins=os.environ.get('CORS_ORIGINS', '*').split(','),
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


@app.on_event("shutdown")
async def shutdown_db_client():
    client.close()
