from urllib.parse import parse_qs
from channels.middleware import BaseMiddleware
from channels.db import database_sync_to_async
from django.contrib.auth.models import AnonymousUser
from django.contrib.auth import get_user_model
from rest_framework_simplejwt.tokens import UntypedToken
from rest_framework_simplejwt.exceptions import InvalidToken, TokenError
from jwt import decode as jwt_decode
from django.conf import settings

User = get_user_model()


@database_sync_to_async
def get_user(validated_token):
    try:
        user_id = validated_token.get("user_id")
        return User.objects.get(id=user_id)
    except User.DoesNotExist:
        return AnonymousUser()


class JWTAuthMiddleware(BaseMiddleware):
    async def __call__(self, scope, receive, send):
        query_string = scope["query_string"].decode()
        query_params = parse_qs(query_string)
        token = query_params.get("token", [None])[0]

        print("=== WS MIDDLEWARE ===")
        print("Query string:", query_string)
        print("Token exists:", bool(token))

        if token is None:
            print("WS AUTH FAILED: No token")
            scope["user"] = AnonymousUser()
            return await super().__call__(scope, receive, send)

        try:
            validated = UntypedToken(token)
            print("Validated token payload:", validated)

            decoded_data = jwt_decode(
                token,
                settings.SECRET_KEY,
                algorithms=["HS256"],
            )
            print("Decoded token:", decoded_data)

            scope["user"] = await get_user(decoded_data)
            print("Resolved user:", scope["user"])
        except (InvalidToken, TokenError, Exception) as e:
            print("WS AUTH ERROR:", str(e))
            scope["user"] = AnonymousUser()

        return await super().__call__(scope, receive, send)