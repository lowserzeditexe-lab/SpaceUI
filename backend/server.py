from fastapi import FastAPI, APIRouter
from fastapi.responses import Response
from dotenv import load_dotenv
from starlette.middleware.cors import CORSMiddleware
from motor.motor_asyncio import AsyncIOMotorClient
import os
import json
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

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Data paths + version registry
# ---------------------------------------------------------------------------
SPACEUI_DIR       = ROOT_DIR / "spaceui"
SPACEUI_LUA_PATH  = SPACEUI_DIR / "spaceui.lua"
COMPONENTS_PATH   = SPACEUI_DIR / "components.json"
EXAMPLES_PATH     = SPACEUI_DIR / "examples.json"
METHODS_PATH      = SPACEUI_DIR / "methods.json"

# Frozen versions of the library, served via /api/spaceui@<version>.lua.
# Add new entries here when cutting a release.
VERSIONS = {
    "1.0.0": SPACEUI_DIR / "spaceui-1.0.0.lua",
}
LATEST_VERSION = "1.0.0"

STATS_ID = "spaceui_loads"


def _load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def _lua_headers() -> dict:
    return {
        "Access-Control-Allow-Origin": "*",
        "Cache-Control": "no-cache",
    }


def _lua_response_from(content: str) -> Response:
    return Response(
        content=content,
        media_type="text/plain; charset=utf-8",
        headers=_lua_headers(),
    )


async def _increment_loads() -> None:
    """Fire-and-forget-ish counter bump. Swallows any DB error."""
    try:
        await db.stats.update_one(
            {"_id": STATS_ID},
            {"$inc": {"count": 1}},
            upsert=True,
        )
    except Exception as e:  # noqa: BLE001
        logger.warning("stats increment failed: %s", e)


# ---------------------------------------------------------------------------
# Core routes
# ---------------------------------------------------------------------------
@api_router.get("/")
async def root():
    return {"message": "SpaceUI backend"}


@api_router.get("/health")
async def health():
    return {"status": "ok", "service": "spaceui"}


@app.get("/spaceui.lua")
async def spaceui_lua_local():
    # Local-only convenience (ingress blocks this externally).
    return _lua_response_from(SPACEUI_LUA_PATH.read_text(encoding="utf-8"))


@api_router.get("/spaceui.lua")
async def spaceui_lua_latest():
    """Public loadstring endpoint — serves the latest library."""
    await _increment_loads()
    return _lua_response_from(SPACEUI_LUA_PATH.read_text(encoding="utf-8"))


@api_router.get("/spaceui@{version}.lua")
async def spaceui_lua_versioned(version: str):
    """Serve a frozen version of the library."""
    path = VERSIONS.get(version)
    if not path or not path.exists():
        return Response(
            content="Version not found\n",
            status_code=404,
            media_type="text/plain; charset=utf-8",
            headers=_lua_headers(),
        )
    await _increment_loads()
    return _lua_response_from(path.read_text(encoding="utf-8"))


@api_router.get("/version")
async def version():
    return {"latest": LATEST_VERSION, "available": list(VERSIONS.keys())}


@api_router.get("/stats")
async def stats():
    doc = await db.stats.find_one({"_id": STATS_ID}, {"_id": 0})
    return Response(
        content=json.dumps({"loads": int(doc["count"]) if doc else 0}),
        media_type="application/json",
        headers={"Cache-Control": "no-cache"},
    )


@api_router.get("/components")
async def components():
    return _load_json(COMPONENTS_PATH)


@api_router.get("/examples")
async def examples():
    return _load_json(EXAMPLES_PATH)


@api_router.get("/examples/{example_id}.lua")
async def example_lua(example_id: str):
    """Serve an individual example as raw Lua for one-liner loadstring installs."""
    items = _load_json(EXAMPLES_PATH)
    match = next((e for e in items if e.get("id") == example_id), None)
    if not match:
        return Response(
            content="Example not found\n",
            status_code=404,
            media_type="text/plain; charset=utf-8",
            headers=_lua_headers(),
        )
    return _lua_response_from(match.get("code", ""))


@api_router.get("/methods")
async def methods():
    return _load_json(METHODS_PATH)


# ---------------------------------------------------------------------------
# Wire up
# ---------------------------------------------------------------------------
app.include_router(api_router)

app.add_middleware(
    CORSMiddleware,
    allow_credentials=True,
    allow_origins=os.environ.get('CORS_ORIGINS', '*').split(','),
    allow_methods=["*"],
    allow_headers=["*"],
)

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
)


@app.on_event("startup")
async def seed_stats_doc():
    try:
        await db.stats.update_one(
            {"_id": STATS_ID},
            {"$setOnInsert": {"count": 0}},
            upsert=True,
        )
    except Exception as e:  # noqa: BLE001
        logger.warning("stats seed failed: %s", e)


@app.on_event("shutdown")
async def shutdown_db_client():
    client.close()
