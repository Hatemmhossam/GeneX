"""
URL configuration for backend project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.2/topics/http/urls/
"""
from django.contrib import admin
from django.urls import path, include
from django.http import HttpResponse

from django.conf import settings
from django.conf.urls.static import static

def home(request):
    return HttpResponse("Welcome to Genex Backend")


urlpatterns = [
    path('', home),
    path('admin/', admin.site.urls),
    path('api/', include('api.urls')),
    path('', include('ml_api.urls')),
    path('api/chat/', include('chat.urls')),
]
urlpatterns += static(
    settings.MEDIA_URL,
    document_root=settings.MEDIA_ROOT
)