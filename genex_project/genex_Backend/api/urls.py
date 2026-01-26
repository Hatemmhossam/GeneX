# api/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import api_root, signup, signin, ProfileView, MedicineViewSet

router = DefaultRouter()
router.register(r'medicines', MedicineViewSet, basename='medicine')

urlpatterns = [
    path('', api_root),
    path('signup/', signup),
    path('signin/', signin),
    path('profile/', ProfileView.as_view(), name='profile'),
    path('', include(router.urls)),   # <-- this adds /medicines/ endpoints
]
