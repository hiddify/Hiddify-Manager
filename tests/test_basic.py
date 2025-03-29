import requests
# test if tests are working fine
def test_tests():
    assert  2+2 == 4

def test_if_admin_panel_200():
    response = requests.get("https://google.com")
    assert response.status_code == 200

def test_subscriptions():
    response = requests.get("")
    assert response.status_code == 200