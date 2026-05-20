# api/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import api_root, signup, signin, ProfileView, MedicineViewSet, SymptomViewSet ,run_twin, get_assigned_doctors
from .views import PatientSearchView
from .views import send_patient_request # Import the new view
from . import views  # <--- THIS LINE IS MISSING
from .views import check_drug_interaction
from .views import analyze_drug
from .views import GeneUploadView # Import the view we wrote earlier
from .views import GeneReportListView
from .views import get_user_risk
from .views import evaluate
import ml_api.views 
from .views import save_report
from .views import mri_predict_gradcam
from . import views
from django.conf import settings
from django.conf.urls.static import static


router = DefaultRouter()
router.register(r'medicines', MedicineViewSet, basename='medicine')
router.register(r'symptoms', SymptomViewSet, basename='symptom') 

urlpatterns = [
    path('', api_root),
    path('signup/', signup),
    path('signin/', signin),
    path('profile/', ProfileView.as_view(), name='profile'),
    path('', include(router.urls)),   # <-- this adds /medicines/ endpoints

    path('run-twin/', run_twin),

    path("twin/run/", views.run_twin, name="run-twin"),

    path('search-patients/', PatientSearchView.as_view(), name='search-patients'),
    path('send-request/', send_patient_request, name='send-request'),
    path('patient/requests/', views.get_patient_requests, name='patient-requests'),
    path('patient/requests/<int:request_id>/update/', views.update_request_status, name='update-request'),
    path('doctor/my-patients/', views.get_my_patients, name='doctor-patients'),
    path('doctor/patient-records/<int:patient_id>/', views.get_patient_medical_details),
    path('doctor/add-note/<int:symptom_id>/', views.add_doctor_note, name='add-doctor-note'),
    path("check-interaction/", check_drug_interaction, name="check_drug_interaction"),
    path('analyze-drug/', analyze_drug, name='analyze-drug'),
    path('gene-upload/', GeneUploadView.as_view(), name='gene-upload'),
    path('gene-reports/', GeneReportListView.as_view(), name='gene-reports'),

    path('doctor/dashboard-stats/', views.doctor_dashboard_stats),
    path('doctor/pending-patients/', views.doctor_pending_patients),
    
    path('get-user-risk/<int:user_id>/', views.get_user_risk, name='get_user_risk'),
    path("evaluate/", evaluate),
    path('predict_xai/', ml_api.views.predict_xai, name='predict_xai'),
    path("save-report/",save_report),
    path('patient/assigned-doctors/', views.get_assigned_doctors, name='get_assigned_doctors'),

    path("mri-predict-gradcam/", mri_predict_gradcam, name="mri_predict_gradcam"),


    path("twin/upload-gene-file/", views.upload_gene_file, name="twin-upload-gene-file"),
    path("twin/run/", views.run_twin, name="run-twin"),
    path("twin/history/", views.get_twin_history, name="twin-history"),
]


urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)