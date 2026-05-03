import json
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from django.contrib.auth import get_user_model
from .models import Conversation, Message

User = get_user_model()


class ChatConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.user = self.scope.get("user")
        self.conversation_id = self.scope["url_route"]["kwargs"]["conversation_id"]
        self.room_group_name = f"chat_{self.conversation_id}"

        if not self.user or self.user.is_anonymous:
            await self.close()
            return

        allowed = await self.user_can_access_conversation(
            self.user.id,
            self.conversation_id,
        )

        if not allowed:
            await self.close()
            return

        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name,
        )

        await self.accept()

    async def disconnect(self, close_code):
        try:
            await self.channel_layer.group_discard(
                self.room_group_name,
                self.channel_name,
            )
        except Exception:
            pass

    async def receive(self, text_data):
        data = json.loads(text_data)
        content = data.get("content", "").strip()

        if not content:
            return

        message_data = await self.save_message(
            self.user.id,
            self.conversation_id,
            content,
        )

        await self.channel_layer.group_send(
            self.room_group_name,
            {
                "type": "chat_message",
                "message": message_data,
            }
        )

    async def chat_message(self, event):
        await self.send(text_data=json.dumps(event["message"]))

    @database_sync_to_async
    def user_can_access_conversation(self, user_id, conversation_id):
        try:
            conversation = Conversation.objects.get(id=conversation_id)
            return (
                conversation.doctor_id == user_id
                or conversation.patient_id == user_id
            )
        except Conversation.DoesNotExist:
            return False

    @database_sync_to_async
    def save_message(self, user_id, conversation_id, content):
        conversation = Conversation.objects.get(id=conversation_id)
        sender = User.objects.get(id=user_id)

        message = Message.objects.create(
            conversation=conversation,
            sender=sender,
            content=content,
        )

        conversation.save(update_fields=["updated_at"])

        return {
            "id": message.id,
            "conversation": conversation.id,
            "sender_id": sender.id,
            "sender_username": sender.username,
            "content": message.content,
            "is_read": message.is_read,
            "created_at": message.created_at.isoformat(),
        }