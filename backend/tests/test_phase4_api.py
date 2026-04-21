"""
Phase 4 SpaceUI API Tests
Tests for:
- Per-example loadstring URLs: /api/examples/{id}.lua
- Versioned loadstring: /api/spaceui@{version}.lua
- Version endpoint: /api/version
- Stats endpoint: /api/stats (MongoDB counter)
- Regression tests for Phase 1/2/3 endpoints
"""
import pytest
import requests
import os
import time

BASE_URL = os.environ.get('REACT_APP_BACKEND_URL', '').rstrip('/')

class TestExampleLuaEndpoints:
    """Tests for /api/examples/{id}.lua endpoints"""
    
    def test_toolkit_esp_lua_returns_200(self):
        """GET /api/examples/toolkit-esp.lua returns 200 text/plain"""
        response = requests.get(f"{BASE_URL}/api/examples/toolkit-esp.lua")
        assert response.status_code == 200, f"Expected 200, got {response.status_code}"
        assert "text/plain" in response.headers.get("Content-Type", ""), \
            f"Expected text/plain, got {response.headers.get('Content-Type')}"
    
    def test_toolkit_esp_lua_has_cors_header(self):
        """GET /api/examples/toolkit-esp.lua has Access-Control-Allow-Origin: *"""
        response = requests.get(f"{BASE_URL}/api/examples/toolkit-esp.lua")
        assert response.headers.get("Access-Control-Allow-Origin") == "*", \
            f"Expected CORS *, got {response.headers.get('Access-Control-Allow-Origin')}"
    
    def test_toolkit_esp_lua_body_starts_with_lua_code(self):
        """GET /api/examples/toolkit-esp.lua body starts with '--' or 'local'"""
        response = requests.get(f"{BASE_URL}/api/examples/toolkit-esp.lua")
        body = response.text.strip()
        assert body.startswith("--") or body.startswith("local"), \
            f"Expected body to start with '--' or 'local', got: {body[:50]}"
    
    def test_hello_world_lua_returns_200(self):
        """GET /api/examples/hello-world.lua returns 200 text/plain with Hello World Lua code"""
        response = requests.get(f"{BASE_URL}/api/examples/hello-world.lua")
        assert response.status_code == 200, f"Expected 200, got {response.status_code}"
        assert "text/plain" in response.headers.get("Content-Type", "")
        # Verify it contains SpaceUI code
        assert "SpaceUI" in response.text, "Expected SpaceUI in hello-world code"
    
    def test_nonexistent_example_returns_404(self):
        """GET /api/examples/does-not-exist.lua returns 404 with text/plain body 'Example not found'"""
        response = requests.get(f"{BASE_URL}/api/examples/does-not-exist.lua")
        assert response.status_code == 404, f"Expected 404, got {response.status_code}"
        assert "text/plain" in response.headers.get("Content-Type", "")
        assert "Example not found" in response.text, \
            f"Expected 'Example not found' in body, got: {response.text}"


class TestVersionEndpoint:
    """Tests for /api/version endpoint"""
    
    def test_version_returns_200_json(self):
        """GET /api/version returns 200 with JSON"""
        response = requests.get(f"{BASE_URL}/api/version")
        assert response.status_code == 200, f"Expected 200, got {response.status_code}"
        data = response.json()
        assert "latest" in data, "Expected 'latest' key in response"
        assert "available" in data, "Expected 'available' key in response"
    
    def test_version_has_correct_structure(self):
        """GET /api/version returns {latest:'1.0.0', available:['1.0.0']}"""
        response = requests.get(f"{BASE_URL}/api/version")
        data = response.json()
        assert data["latest"] == "1.0.0", f"Expected latest='1.0.0', got {data['latest']}"
        assert isinstance(data["available"], list), "Expected 'available' to be a list"
        assert "1.0.0" in data["available"], "Expected '1.0.0' in available versions"


class TestVersionedLuaEndpoints:
    """Tests for /api/spaceui@{version}.lua endpoints"""
    
    def test_versioned_lua_1_0_0_returns_200(self):
        """GET /api/spaceui@1.0.0.lua returns 200 text/plain"""
        response = requests.get(f"{BASE_URL}/api/spaceui@1.0.0.lua")
        assert response.status_code == 200, f"Expected 200, got {response.status_code}"
        assert "text/plain" in response.headers.get("Content-Type", "")
    
    def test_versioned_lua_1_0_0_starts_with_header(self):
        """GET /api/spaceui@1.0.0.lua body starts with '--[[ SpaceUI v1.0.0'"""
        response = requests.get(f"{BASE_URL}/api/spaceui@1.0.0.lua")
        body = response.text.strip()
        assert body.startswith("--[[ SpaceUI v1.0.0"), \
            f"Expected body to start with '--[[ SpaceUI v1.0.0', got: {body[:50]}"
    
    def test_nonexistent_version_returns_404(self):
        """GET /api/spaceui@9.9.9.lua returns 404 plain-text 'Version not found'"""
        response = requests.get(f"{BASE_URL}/api/spaceui@9.9.9.lua")
        assert response.status_code == 404, f"Expected 404, got {response.status_code}"
        assert "text/plain" in response.headers.get("Content-Type", "")
        assert "Version not found" in response.text, \
            f"Expected 'Version not found' in body, got: {response.text}"


class TestStatsEndpoint:
    """Tests for /api/stats endpoint (MongoDB counter)"""
    
    def test_stats_returns_200_json(self):
        """GET /api/stats returns 200 JSON {loads:<integer>}"""
        response = requests.get(f"{BASE_URL}/api/stats")
        assert response.status_code == 200, f"Expected 200, got {response.status_code}"
        data = response.json()
        assert "loads" in data, "Expected 'loads' key in response"
        assert isinstance(data["loads"], int), f"Expected loads to be int, got {type(data['loads'])}"
    
    def test_stats_loads_is_at_least_1_after_warmup(self):
        """GET /api/stats.loads is at least 1 after warm-up (hitting spaceui.lua)"""
        # First hit spaceui.lua to ensure counter is incremented
        requests.get(f"{BASE_URL}/api/spaceui.lua")
        time.sleep(0.3)  # Wait for DB write
        
        response = requests.get(f"{BASE_URL}/api/stats")
        data = response.json()
        assert data["loads"] >= 1, f"Expected loads >= 1, got {data['loads']}"


class TestStatsIncrement:
    """Tests for stats increment behavior"""
    
    def test_spaceui_lua_increments_stats(self):
        """Hitting /api/spaceui.lua twice increments /api/stats.loads by 2"""
        # Get initial count
        initial_response = requests.get(f"{BASE_URL}/api/stats")
        initial_count = initial_response.json()["loads"]
        
        # Hit spaceui.lua twice
        requests.get(f"{BASE_URL}/api/spaceui.lua")
        time.sleep(0.3)
        requests.get(f"{BASE_URL}/api/spaceui.lua")
        time.sleep(0.3)
        
        # Check new count
        final_response = requests.get(f"{BASE_URL}/api/stats")
        final_count = final_response.json()["loads"]
        
        assert final_count >= initial_count + 2, \
            f"Expected count to increase by at least 2. Initial: {initial_count}, Final: {final_count}"
    
    def test_versioned_lua_also_increments_stats(self):
        """Hitting /api/spaceui@1.0.0.lua also increments /api/stats.loads"""
        # Get initial count
        initial_response = requests.get(f"{BASE_URL}/api/stats")
        initial_count = initial_response.json()["loads"]
        
        # Hit versioned lua
        requests.get(f"{BASE_URL}/api/spaceui@1.0.0.lua")
        time.sleep(0.3)
        
        # Check new count
        final_response = requests.get(f"{BASE_URL}/api/stats")
        final_count = final_response.json()["loads"]
        
        assert final_count >= initial_count + 1, \
            f"Expected count to increase by at least 1. Initial: {initial_count}, Final: {final_count}"


class TestRegressionPhase1:
    """Regression tests for Phase 1 endpoints"""
    
    def test_health_endpoint(self):
        """GET /api/health returns 200 with {status: 'ok', service: 'spaceui'}"""
        response = requests.get(f"{BASE_URL}/api/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "ok"
        assert data["service"] == "spaceui"
    
    def test_spaceui_lua_endpoint(self):
        """GET /api/spaceui.lua returns 200 text/plain with Lua content"""
        response = requests.get(f"{BASE_URL}/api/spaceui.lua")
        assert response.status_code == 200
        assert "text/plain" in response.headers.get("Content-Type", "")
        assert response.headers.get("Access-Control-Allow-Origin") == "*"


class TestRegressionPhase3:
    """Regression tests for Phase 3 endpoints"""
    
    def test_components_endpoint(self):
        """GET /api/components returns 200 with 14 components"""
        response = requests.get(f"{BASE_URL}/api/components")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) == 14, f"Expected 14 components, got {len(data)}"
    
    def test_examples_endpoint(self):
        """GET /api/examples returns 200 with 3 examples"""
        response = requests.get(f"{BASE_URL}/api/examples")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) == 3, f"Expected 3 examples, got {len(data)}"
    
    def test_methods_endpoint(self):
        """GET /api/methods returns 200 with 21 methods"""
        response = requests.get(f"{BASE_URL}/api/methods")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) == 21, f"Expected 21 methods, got {len(data)}"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
