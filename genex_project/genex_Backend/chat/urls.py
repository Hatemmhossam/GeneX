from django.urls import path
from . import views

urlpatterns = [
    path('open/', views.open_or_create_conversation, name='open_or_create_conversation'),
    path('conversations/', views.my_conversations, name='my_conversations'),
    path('conversations/<int:conversation_id>/messages/', views.get_conversation_messages, name='get_conversation_messages'),
    path('conversations/<int:conversation_id>/read/', views.mark_messages_as_read, name='mark_messages_as_read'),
     path('conversations/<int:conversation_id>/upload/', views.upload_attachment_message, name='upload_attachment_message'),
]