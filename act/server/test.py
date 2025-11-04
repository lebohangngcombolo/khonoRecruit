import requests

login_url = "http://localhost:5000/api/auth/login"
data = {"email": "lebohangngcombolo@gmail.com", "password": "stenaman"}

r = requests.post(login_url, json=data)
tokens = r.json()

access_token = tokens.get("access_token")
print("Access Token:", access_token)
