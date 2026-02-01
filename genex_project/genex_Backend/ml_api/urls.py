from django.urls import path
from . import views

urlpatterns = [
    path('predict_xai/', views.predict_xai, name='predict_xai'),
]