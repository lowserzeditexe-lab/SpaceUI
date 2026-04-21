"""
SpaceUI Backend API Tests - Phase 1
Tests for /api/health and /spaceui.lua endpoints
"""
import pytest
import requests
import os

# Use the public URL for testing
BASE_URL = os.environ.get('REACT_APP_BACKEND_URL', 'https://32afa6c7-75d5-4dc2-befe-cab0bd3d4211.preview.emergentagent.com').rstrip('/')


class TestHealthEndpoint:
    """Tests for /api/health endpoint"""
    
    def test_health_returns_200(self):
        """GET /api/health should return 200"""
        response = requests.get(f"{BASE_URL}/api/health")
        assert response.status_code == 200, f"Expected 200, got {response.status_code}"
        print(f"✓ /api/health returns 200")
    
    def test_health_returns_correct_json(self):
        """GET /api/health should return {status: 'ok', service: 'spaceui'}"""
        response = requests.get(f"{BASE_URL}/api/health")
        data = response.json()
        
        assert "status" in data, "Response missing 'status' field"
        assert data["status"] == "ok", f"Expected status 'ok', got '{data['status']}'"
        
        assert "service" in data, "Response missing 'service' field"
        assert data["service"] == "spaceui", f"Expected service 'spaceui', got '{data['service']}'"
        
        print(f"✓ /api/health returns correct JSON: {data}")


class TestSpaceUILuaEndpoint:
    """Tests for /api/spaceui.lua endpoint (via /api prefix for K8s ingress)"""
    
    def test_spaceui_lua_returns_200(self):
        """GET /api/spaceui.lua should return 200"""
        response = requests.get(f"{BASE_URL}/api/spaceui.lua")
        assert response.status_code == 200, f"Expected 200, got {response.status_code}"
        print(f"✓ /api/spaceui.lua returns 200")
    
    def test_spaceui_lua_content_type(self):
        """GET /api/spaceui.lua should return Content-Type: text/plain; charset=utf-8"""
        response = requests.get(f"{BASE_URL}/api/spaceui.lua")
        content_type = response.headers.get("Content-Type", "")
        
        assert "text/plain" in content_type, f"Expected 'text/plain' in Content-Type, got '{content_type}'"
        assert "charset=utf-8" in content_type, f"Expected 'charset=utf-8' in Content-Type, got '{content_type}'"
        
        print(f"✓ /api/spaceui.lua Content-Type: {content_type}")
    
    def test_spaceui_lua_cors_header(self):
        """GET /api/spaceui.lua should have Access-Control-Allow-Origin: * header"""
        response = requests.get(f"{BASE_URL}/api/spaceui.lua")
        cors_header = response.headers.get("Access-Control-Allow-Origin", "")
        
        assert cors_header == "*", f"Expected CORS header '*', got '{cors_header}'"
        
        print(f"✓ /api/spaceui.lua CORS header: {cors_header}")
    
    def test_spaceui_lua_body_content(self):
        """GET /api/spaceui.lua body should contain placeholder comment and return {}"""
        response = requests.get(f"{BASE_URL}/api/spaceui.lua")
        body = response.text
        
        assert "-- SpaceUI v0.1 (Phase 2 will implement this)" in body, \
            f"Expected placeholder comment in body, got: {body}"
        
        assert "return {}" in body, f"Expected 'return {{}}' in body, got: {body}"
        
        print(f"✓ /api/spaceui.lua body content correct:\n{body}")


class TestOpenAPIEndpoint:
    """Tests for /api/docs (OpenAPI) endpoint"""
    
    def test_openapi_docs_accessible(self):
        """GET /api/docs should return 200"""
        response = requests.get(f"{BASE_URL}/api/docs")
        assert response.status_code == 200, f"Expected 200, got {response.status_code}"
        print(f"✓ /api/docs returns 200")
    
    def test_openapi_json_accessible(self):
        """GET /api/openapi.json should return 200"""
        response = requests.get(f"{BASE_URL}/api/openapi.json")
        assert response.status_code == 200, f"Expected 200, got {response.status_code}"
        
        data = response.json()
        assert "openapi" in data, "OpenAPI spec missing 'openapi' field"
        assert "info" in data, "OpenAPI spec missing 'info' field"
        
        print(f"✓ /api/openapi.json returns valid OpenAPI spec")


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
