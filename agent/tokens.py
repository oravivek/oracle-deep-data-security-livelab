"""Optional Entra client-credentials token for delegated LOCAL end users."""
import getpass
import json
import os
import uuid
from urllib.parse import urlencode
from urllib.request import Request, urlopen


def client_credentials_token():
    tenant = str(uuid.UUID(os.environ["ENTRA_TENANT_ID"]))
    client_id = str(uuid.UUID(os.environ["ENTRA_CLIENT_ID"]))
    scope = os.environ["ENTRA_DB_SCOPE"]
    if not scope.endswith("/.default"):
        raise ValueError("ENTRA_DB_SCOPE must be database-resource/.default")
    secret = getpass.getpass("Entra application client secret: ")
    payload = urlencode({"grant_type": "client_credentials",
                         "client_id": client_id, "client_secret": secret,
                         "scope": scope}).encode()
    request = Request(
        f"https://login.microsoftonline.com/{tenant}/oauth2/v2.0/token",
        data=payload,
        headers={"Content-Type": "application/x-www-form-urlencoded"})
    with urlopen(request, timeout=30) as response:
        result = json.load(response)
    token = result.get("access_token")
    if not token:
        raise RuntimeError("No application database-access token issued")
    return token
