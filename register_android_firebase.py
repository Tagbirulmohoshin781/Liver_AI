import json
import base64
import time
import requests
from google.oauth2 import service_account
from google.auth.transport.requests import Request

SERVICE_ACCOUNT_FILE = "firebase-service-account.json"
PROJECT_ID = "liver-ai-medical-assistant"
PACKAGE_NAME = "com.example.liver_disease_detection_app"
SHA1_HASH = "C9937FAAD5A1C8EB68D165FEF3BD7911CFC1C0C4"

def get_access_token():
    scopes = ["https://www.googleapis.com/auth/cloud-platform", "https://www.googleapis.com/auth/firebase"]
    creds = service_account.Credentials.from_service_account_file(SERVICE_ACCOUNT_FILE, scopes=scopes)
    creds.refresh(Request())
    return creds.token

def main():
    token = get_access_token()
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }

    # 1. Poll for Android apps
    list_url = f"https://firebase.googleapis.com/v1beta1/projects/{PROJECT_ID}/androidApps"
    app_id = None
    for attempt in range(10):
        res = requests.get(list_url, headers=headers)
        print(f"Attempt {attempt+1} List:", res.status_code, res.text)
        if res.status_code == 200:
            apps = res.json().get("apps", [])
            for a in apps:
                print("App found:", a)
                if a.get("packageName") == PACKAGE_NAME:
                    app_id = a.get("appId")
                    break
        if app_id:
            break
        time.sleep(2)

    if not app_id:
        print("Could not find Android app with package name:", PACKAGE_NAME)
        return

    print("Found Target App ID:", app_id)

    # 2. Add SHA-1 certificate
    sha_url = f"https://firebase.googleapis.com/v1beta1/projects/{PROJECT_ID}/androidApps/{app_id}/sha"
    sha_payload = {
        "shaHash": SHA1_HASH,
        "certType": "SHA_1"
    }
    sha_res = requests.post(sha_url, headers=headers, json=sha_payload)
    print("Add SHA1 Response:", sha_res.status_code, sha_res.text)

    # 3. Download google-services.json
    config_url = f"https://firebase.googleapis.com/v1beta1/projects/{PROJECT_ID}/androidApps/{app_id}/config"
    cfg_res = requests.get(config_url, headers=headers)
    print("Get Config Response:", cfg_res.status_code)
    if cfg_res.status_code == 200:
        cfg_data = cfg_res.json()
        b64_content = cfg_data.get("configFileContents", "")
        if b64_content:
            raw_json = base64.b64decode(b64_content).decode("utf-8")
            dest_path = "Liver Disease Detection App/android/app/google-services.json"
            with open(dest_path, "w", encoding="utf-8") as f:
                f.write(raw_json)
            print("Successfully saved google-services.json to:", dest_path)
            
            parsed = json.loads(raw_json)
            for c in parsed.get("client", []):
                for oauth in c.get("oauth_client", []):
                    print("OAuth Client ID:", oauth.get("client_id"), "Type:", oauth.get("client_type"))

if __name__ == "__main__":
    main()
