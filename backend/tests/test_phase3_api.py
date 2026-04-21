"""
Phase 3 Backend API Tests for SpaceUI
Tests for /api/components, /api/examples, /api/methods endpoints
"""
import pytest
import requests
import os
import re

BASE_URL = os.environ.get('REACT_APP_BACKEND_URL', '').rstrip('/')

class TestComponentsEndpoint:
    """Tests for GET /api/components endpoint"""
    
    def test_components_returns_200(self):
        """GET /api/components returns 200 status"""
        response = requests.get(f"{BASE_URL}/api/components")
        assert response.status_code == 200, f"Expected 200, got {response.status_code}"
        print("✓ /api/components returns 200")
    
    def test_components_returns_json_array(self):
        """GET /api/components returns JSON array"""
        response = requests.get(f"{BASE_URL}/api/components")
        data = response.json()
        assert isinstance(data, list), f"Expected list, got {type(data)}"
        print(f"✓ /api/components returns JSON array with {len(data)} items")
    
    def test_components_has_exactly_14_items(self):
        """GET /api/components returns exactly 14 components"""
        response = requests.get(f"{BASE_URL}/api/components")
        data = response.json()
        assert len(data) == 14, f"Expected 14 components, got {len(data)}"
        print("✓ /api/components has exactly 14 components")
    
    def test_components_have_required_fields(self):
        """Each component has id, name, group, description, snippet, props[]"""
        response = requests.get(f"{BASE_URL}/api/components")
        data = response.json()
        required_fields = ['id', 'name', 'group', 'description', 'snippet', 'props']
        
        for comp in data:
            for field in required_fields:
                assert field in comp, f"Component {comp.get('id', 'unknown')} missing field: {field}"
            assert isinstance(comp['props'], list), f"Component {comp['id']} props should be a list"
        print("✓ All components have required fields: id, name, group, description, snippet, props[]")
    
    def test_components_ids_match_expected(self):
        """Components have expected IDs"""
        response = requests.get(f"{BASE_URL}/api/components")
        data = response.json()
        expected_ids = {
            'window', 'tab', 'section', 'button', 'toggle', 'slider', 
            'dropdown', 'input', 'keybind', 'colorpicker', 'label', 
            'paragraph', 'divider', 'notification'
        }
        actual_ids = {comp['id'] for comp in data}
        assert actual_ids == expected_ids, f"Missing IDs: {expected_ids - actual_ids}, Extra IDs: {actual_ids - expected_ids}"
        print(f"✓ All 14 expected component IDs present: {sorted(expected_ids)}")


class TestExamplesEndpoint:
    """Tests for GET /api/examples endpoint"""
    
    def test_examples_returns_200(self):
        """GET /api/examples returns 200 status"""
        response = requests.get(f"{BASE_URL}/api/examples")
        assert response.status_code == 200, f"Expected 200, got {response.status_code}"
        print("✓ /api/examples returns 200")
    
    def test_examples_returns_json_array(self):
        """GET /api/examples returns JSON array"""
        response = requests.get(f"{BASE_URL}/api/examples")
        data = response.json()
        assert isinstance(data, list), f"Expected list, got {type(data)}"
        print(f"✓ /api/examples returns JSON array with {len(data)} items")
    
    def test_examples_has_exactly_3_items(self):
        """GET /api/examples returns exactly 3 examples"""
        response = requests.get(f"{BASE_URL}/api/examples")
        data = response.json()
        assert len(data) == 3, f"Expected 3 examples, got {len(data)}"
        print("✓ /api/examples has exactly 3 examples")
    
    def test_examples_ids_match_expected(self):
        """Examples have expected IDs: hello-world, settings-panel, toolkit-esp"""
        response = requests.get(f"{BASE_URL}/api/examples")
        data = response.json()
        expected_ids = {'hello-world', 'settings-panel', 'toolkit-esp'}
        actual_ids = {ex['id'] for ex in data}
        assert actual_ids == expected_ids, f"Missing IDs: {expected_ids - actual_ids}, Extra IDs: {actual_ids - expected_ids}"
        print(f"✓ All 3 expected example IDs present: {sorted(expected_ids)}")
    
    def test_toolkit_esp_is_featured(self):
        """toolkit-esp example has featured: true"""
        response = requests.get(f"{BASE_URL}/api/examples")
        data = response.json()
        toolkit = next((ex for ex in data if ex['id'] == 'toolkit-esp'), None)
        assert toolkit is not None, "toolkit-esp example not found"
        assert toolkit.get('featured') is True, f"toolkit-esp featured should be True, got {toolkit.get('featured')}"
        print("✓ toolkit-esp has featured: true")
    
    def test_toolkit_esp_has_200_plus_lines(self):
        """toolkit-esp code has 200+ lines"""
        response = requests.get(f"{BASE_URL}/api/examples")
        data = response.json()
        toolkit = next((ex for ex in data if ex['id'] == 'toolkit-esp'), None)
        assert toolkit is not None, "toolkit-esp example not found"
        code = toolkit.get('code', '')
        line_count = len(code.split('\n'))
        assert line_count >= 200, f"toolkit-esp should have 200+ lines, got {line_count}"
        print(f"✓ toolkit-esp has {line_count} lines (200+ required)")
    
    def test_toolkit_esp_monochrome_colors_only(self):
        """toolkit-esp code contains only monochrome Color3 values (no saturated colors)"""
        response = requests.get(f"{BASE_URL}/api/examples")
        data = response.json()
        toolkit = next((ex for ex in data if ex['id'] == 'toolkit-esp'), None)
        assert toolkit is not None, "toolkit-esp example not found"
        code = toolkit.get('code', '')
        
        # Find all Color3.fromRGB calls
        rgb_pattern = r'Color3\.fromRGB\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)'
        matches = re.findall(rgb_pattern, code)
        
        saturated_colors = []
        for r, g, b in matches:
            r, g, b = int(r), int(g), int(b)
            # Check if color is saturated (values differ significantly)
            max_val = max(r, g, b)
            min_val = min(r, g, b)
            # If difference is > 50 and not grayscale, it's saturated
            if max_val - min_val > 50:
                saturated_colors.append((r, g, b))
        
        # Also check Color3.new calls
        new_pattern = r'Color3\.new\s*\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)\s*\)'
        new_matches = re.findall(new_pattern, code)
        
        for r, g, b in new_matches:
            r, g, b = float(r), float(g), float(b)
            max_val = max(r, g, b)
            min_val = min(r, g, b)
            if max_val - min_val > 0.2:  # For 0-1 scale
                saturated_colors.append((r, g, b))
        
        assert len(saturated_colors) == 0, f"Found saturated colors in toolkit-esp: {saturated_colors}"
        print(f"✓ toolkit-esp contains only monochrome colors (checked {len(matches) + len(new_matches)} Color3 calls)")


class TestMethodsEndpoint:
    """Tests for GET /api/methods endpoint"""
    
    def test_methods_returns_200(self):
        """GET /api/methods returns 200 status"""
        response = requests.get(f"{BASE_URL}/api/methods")
        assert response.status_code == 200, f"Expected 200, got {response.status_code}"
        print("✓ /api/methods returns 200")
    
    def test_methods_returns_json_array(self):
        """GET /api/methods returns JSON array"""
        response = requests.get(f"{BASE_URL}/api/methods")
        data = response.json()
        assert isinstance(data, list), f"Expected list, got {type(data)}"
        print(f"✓ /api/methods returns JSON array with {len(data)} items")
    
    def test_methods_has_20_plus_items(self):
        """GET /api/methods returns 20+ methods"""
        response = requests.get(f"{BASE_URL}/api/methods")
        data = response.json()
        assert len(data) >= 20, f"Expected 20+ methods, got {len(data)}"
        print(f"✓ /api/methods has {len(data)} methods (20+ required)")
    
    def test_methods_have_required_fields(self):
        """Each method has id, group, signature, description, options, returns, example"""
        response = requests.get(f"{BASE_URL}/api/methods")
        data = response.json()
        required_fields = ['id', 'group', 'signature', 'description', 'returns', 'example']
        
        for method in data:
            for field in required_fields:
                assert field in method, f"Method {method.get('id', 'unknown')} missing field: {field}"
            # options can be empty array but should exist
            assert 'options' in method, f"Method {method['id']} missing 'options' field"
        print("✓ All methods have required fields: id, group, signature, description, options, returns, example")


class TestPhase1Regression:
    """Regression tests for Phase 1 endpoints"""
    
    def test_health_endpoint(self):
        """GET /api/health returns 200 with correct response"""
        response = requests.get(f"{BASE_URL}/api/health")
        assert response.status_code == 200
        data = response.json()
        assert data.get('status') == 'ok'
        assert data.get('service') == 'spaceui'
        print("✓ /api/health returns {status: 'ok', service: 'spaceui'}")
    
    def test_spaceui_lua_endpoint(self):
        """GET /api/spaceui.lua returns 200 with Lua content"""
        response = requests.get(f"{BASE_URL}/api/spaceui.lua")
        assert response.status_code == 200
        assert 'text/plain' in response.headers.get('Content-Type', '')
        assert len(response.text) > 100, "Lua file should have substantial content"
        print(f"✓ /api/spaceui.lua returns Lua content ({len(response.text)} chars)")


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
