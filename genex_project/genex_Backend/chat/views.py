from django.contrib.auth import get_user_model
from django.db.models import Q
from rest_framework.decorators import api_view, permission_classes, authentication_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from rest_framework_simplejwt.authentication import JWTAuthentication

from .models import Conversation, Message
from .serializers import ConversationSerializer, MessageSerializer
from .utils import can_doctor_and_patient_chat

User = get_user_model()


@api_view(['POST'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def open_or_create_conversation(request):
    user = request.user
    doctor_id = request.data.get('doctor_id')
    patient_id = request.data.get('patient_id')

    if not doctor_id or not patient_id:
        return Response(
            {"error": "doctor_id and patient_id are required"},
            status=status.HTTP_400_BAD_REQUEST
        )

    try:
        doctor = User.objects.get(id=doctor_id)
        patient = User.objects.get(id=patient_id)
    except User.DoesNotExist:
        return Response({"error": "Doctor or patient not found"}, status=status.HTTP_404_NOT_FOUND)

    if not can_doctor_and_patient_chat(doctor, patient):
        return Response({"error": "Chat not allowed"}, status=status.HTTP_403_FORBIDDEN)

    if user.id not in [doctor.id, patient.id]:
        return Response({"error": "You are not part of this conversation"}, status=status.HTTP_403_FORBIDDEN)

    conversation, created = Conversation.objects.get_or_create(
        doctor=doctor,
        patient=patient
    )

    serializer = ConversationSerializer(conversation)
    return Response(serializer.data, status=status.HTTP_200_OK)


@api_view(['GET'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def get_conversation_messages(request, conversation_id):
    user = request.user

    try:
        conversation = Conversation.objects.get(id=conversation_id)
    except Conversation.DoesNotExist:
        return Response({"error": "Conversation not found"}, status=status.HTTP_404_NOT_FOUND)

    if user != conversation.doctor and user != conversation.patient:
        return Response({"error": "Access denied"}, status=status.HTTP_403_FORBIDDEN)

    messages = conversation.messages.all()
    serializer = MessageSerializer(messages, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)


@api_view(['GET'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def my_conversations(request):
    user = request.user

    conversations = Conversation.objects.filter(
        Q(doctor=user) | Q(patient=user)
    ).distinct()

    serializer = ConversationSerializer(conversations, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)


@api_view(['POST'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def mark_messages_as_read(request, conversation_id):
    user = request.user

    try:
        conversation = Conversation.objects.get(id=conversation_id)
    except Conversation.DoesNotExist:
        return Response({"error": "Conversation not found"}, status=status.HTTP_404_NOT_FOUND)

    if user != conversation.doctor and user != conversation.patient:
        return Response({"error": "Access denied"}, status=status.HTTP_403_FORBIDDEN)

    conversation.messages.exclude(sender=user).filter(is_read=False).update(is_read=True)

    return Response({"message": "Messages marked as read"}, status=status.HTTP_200_OK)


@api_view(['GET'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def my_conversations(request):
    user = request.user

    conversations = Conversation.objects.filter(
        Q(doctor=user) | Q(patient=user)
    ).distinct()

    serializer = ConversationSerializer(conversations, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)
 
@api_view(['POST'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def upload_attachment_message(request, conversation_id):
    user = request.user

    try:
        conversation = Conversation.objects.get(id=conversation_id)
    except Conversation.DoesNotExist:
        return Response({"error": "Conversation not found"}, status=404)

    if user != conversation.doctor and user != conversation.patient:
        return Response({"error": "Access denied"}, status=403)

    file_obj = request.FILES.get('file')
    content = request.data.get('content', '')

    if not file_obj:
        return Response({"error": "No file uploaded"}, status=400)

    message = Message.objects.create(
        conversation=conversation,
        sender=user,
        content=content,
        attachment=file_obj,
        attachment_name=file_obj.name,
    )

    serializer = MessageSerializer(message, context={'request': request})
    return Response(serializer.data, status=201)