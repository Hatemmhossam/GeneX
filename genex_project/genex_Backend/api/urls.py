# api/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import api_root, signup, signin, ProfileView, MedicineViewSet, SymptomViewSet
from .views import PatientSearchView
from .views import send_patient_request # Import the new view
from . import views  # <--- THIS LINE IS MISSING

router = DefaultRouter()
router.register(r'medicines', MedicineViewSet, basename='medicine')
router.register(r'symptoms', SymptomViewSet, basename='symptom') 

urlpatterns = [
    path('', api_root),
    path('signup/', signup),
    path('signin/', signin),
    path('profile/', ProfileView.as_view(), name='profile'),
    path('', include(router.urls)),   # <-- this adds /medicines/ endpoints
    path('search-patients/', PatientSearchView.as_view(), name='search-patients'),
    path('send-request/', send_patient_request, name='send-request'),
    path('patient/requests/', views.get_patient_requests, name='patient-requests'),
    path('patient/requests/<int:request_id>/update/', views.update_request_status, name='update-request'),
    path('doctor/my-patients/', views.get_my_patients, name='doctor-patients'),
    path('doctor/patient-records/<int:patient_id>/', views.get_patient_medical_details),
    path('doctor/add-note/<int:symptom_id>/', views.add_doctor_note, name='add-doctor-note'),
]