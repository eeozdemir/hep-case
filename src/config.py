import os
import json

try:
    with open('db_config.json') as f:
        default_config = json.load(f)
except FileNotFoundError:
    default_config = {
        "db": {
            "url": "mongodb://localhost:27017/hep-db",
            "name": "hep-db"
        }
    }

config = {
    "db": {
        "url": os.getenv("MONGO_URI", default_config["db"]["url"]),
        "name": os.getenv("MONGO_DB_NAME", default_config["db"]["name"])
    }
}