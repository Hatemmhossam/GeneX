# api/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import api_root, signup, signin, ProfileView, MedicineViewSet, SymptomViewSet, PatientListView
from .views import PatientListView
from .views import PatientSearchView
from .views import send_patient_request # Import the new view


router = DefaultRouter()
router.register(r'medicines', MedicineViewSet, basename='medicine')
router.register(r'symptoms', SymptomViewSet, basename='symptom') 

urlpatterns = [
    path('', api_root),
    path('signup/', signup),
    path('signin/', signin),
    path('profile/', ProfileView.as_view(), name='profile'),
    path('', include(router.urls)),   # <-- this adds /medicines/ endpoints
    path('doctor/patients/', PatientListView.as_view(), name='doctor-patients'),
    path('search-patients/', PatientSearchView.as_view(), name='search-patients'),
    path('send-request/', send_patient_request, name='send-request'),
]