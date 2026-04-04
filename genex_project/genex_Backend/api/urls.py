# api/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
<<<<<<< Updated upstream
from .views import api_root, signup, signin, ProfileView, MedicineViewSet, SymptomViewSet
=======
from .views import api_root, signup, signin, ProfileView, MedicineViewSet, SymptomViewSet, PatientListView
from .views import PatientListView
from .views import GeneUploadView # Import the view we wrote earlier


>>>>>>> Stashed changes

router = DefaultRouter()
router.register(r'medicines', MedicineViewSet, basename='medicine')
router.register(r'symptoms', SymptomViewSet, basename='symptom') 

urlpatterns = [
    path('', api_root),
    path('signup/', signup),
    path('signin/', signin),
    path('profile/', ProfileView.as_view(), name='profile'),
    path('', include(router.urls)),   # <-- this adds /medicines/ endpoints
<<<<<<< Updated upstream
=======
    path('doctor/patients/', PatientListView.as_view(), name='doctor-patients'),
    path('gene-upload/', GeneUploadView.as_view(), name='gene-upload'),
>>>>>>> Stashed changes
]
