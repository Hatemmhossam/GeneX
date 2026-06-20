import os
import json
import firebase_admin
from firebase_admin import credentials

if not firebase_admin._apps:
    firebase_json = os.environ.get("FIREBASE_CREDENTIALS")

    if firebase_json:
        cred_dict = json.loads(firebase_json)
        cred = credentials.Certificate(cred_dict)
    else:
        cred_path = os.path.join(os.getcwd(), "firebase-admin-sdk.json")
        cred = credentials.Certificate(cred_path)

    firebase_admin.initialize_app(cred)