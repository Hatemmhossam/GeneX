from rest_framework import serializers
from .models import Conversation, Message


class MessageSerializer(serializers.ModelSerializer):
    sender_id = serializers.IntegerField(source='sender.id', read_only=True)
    sender_username = serializers.CharField(source='sender.username', read_only=True)
    
    # ✅ NEW: return full file URL
    attachment_url = serializers.SerializerMethodField()

    class Meta:
        model = Message
        fields = [
            'id',
            'conversation',
            'sender_id',
            'sender_username',
            'content',
            'attachment',          # ✅ NEW
            'attachment_name',     # ✅ NEW
            'attachment_url',      # ✅ NEW
            'is_read',
            'created_at',
        ]

    def get_attachment_url(self, obj):
        request = self.context.get('request')

        if obj.attachment:
            if request:
                return request.build_absolute_uri(obj.attachment.url)
            return obj.attachment.url
        
        return None


class ConversationSerializer(serializers.ModelSerializer):
    doctor_id = serializers.IntegerField(source='doctor.id', read_only=True)
    patient_id = serializers.IntegerField(source='patient.id', read_only=True)
    doctor_username = serializers.CharField(source='doctor.username', read_only=True)
    patient_username = serializers.CharField(source='patient.username', read_only=True)

    last_message = serializers.SerializerMethodField()
    unread_count = serializers.SerializerMethodField()

    class Meta:
        model = Conversation
        fields = [
            'id',
            'doctor_id',
            'patient_id',
            'doctor_username',
            'patient_username',
            'created_at',
            'updated_at',
            'last_message',
            'unread_count',
        ]

    def get_last_message(self, obj):
        last = obj.messages.order_by('-created_at').first()

        if not last:
            return None

        return {
            'id': last.id,
            'content': last.content,
            'sender_id': last.sender.id,
            'sender_username': last.sender.username,
            'created_at': last.created_at.isoformat(),
            'is_read': last.is_read,
            'attachment_name': last.attachment_name,   # ✅ NEW
            'attachment_url': last.attachment.url if last.attachment else None,  # ✅ NEW
        }

    def get_unread_count(self, obj):
        request = self.context.get('request')

        if not request or not request.user.is_authenticated:
            return 0

        return obj.messages.exclude(
            sender=request.user
        ).filter(
            is_read=False
        ).count()