import os
import json
from pymongo import MongoClient

MONGODB_URI = os.getenv("MONGO_URI")
DB_NAME = "database"

client = MongoClient(MONGODB_URI)
db = client[DB_NAME]

def clean_imports(imports):
    return list(set(imports)) if imports else []

def clean_implements(implements):
    return list(set(implements)) if implements else []

def lambda_handler(event, context):
    try:
        user = event.get("user")
        project = event.get("project")
        collection = db[user + "/" + project]

        if not user or not project:
            return {
                "statusCode": 400,
                "body": json.dumps({"error": "Se requieren 'user' y 'project' en la solicitud."})
            }

        project_path = f"{user}/{project}"

        query = {"filename": {"$exists": True}}
        files = collection.find(query)

        dataset = []
        for file in files:
            filename = file.get("filename", "Unknown")
            code_imports = clean_imports(file.get("imports", []))
            code_implements = clean_implements(file.get("implements", []))
            is_main = file.get("is_main", False)

            dataset.append({
                "filename": filename,
                "code_imports": code_imports,
                "code_implements": code_implements,
                "is_main": is_main
            })

        return {
            "statusCode": 200,
            "body": json.dumps(dataset)
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }
