# api/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import api_root, approve_report_permission, pending_report_permissions, pending_report_permissions, request_report_permission, signup, signin, ProfileView, MedicineViewSet, SymptomViewSet ,run_twin, get_assigned_doctors
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
router.register(r'medicines', MedicineViewSet, basename='medicine')#register medicine endpoints
router.register(r'symptoms', SymptomViewSet, basename='symptom') #register symptom endpoints

urlpatterns = [
    path('', api_root),
    path('signup/', signup),#user registration
    path('signin/', signin),#user login
    path('profile/', ProfileView.as_view(), name='profile'),#view and update user profile
    path('', include(router.urls)),   # <-- this adds /medicines/ endpoints

    path('run-twin/', run_twin),

    path("twin/run/", views.run_twin, name="run-twin"),#run twin simulation with selected drugs and gene expression data

    path('search-patients/', PatientSearchView.as_view(), name='search-patients'),#doctor search for patients
    path('send-request/', send_patient_request, name='send-request'),#doctor senf request to patients
    path('patient/requests/', views.get_patient_requests, name='patient-requests'),#patient view requests from doctors
    path('patient/requests/<int:request_id>/update/', views.update_request_status, name='update-request'),#patient accept or reject doctor request
    path('doctor/my-patients/', views.get_my_patients, name='doctor-patients'),#doctor view accepted patients
    path('doctor/patient-records/<int:patient_id>/', views.get_patient_medical_details),#doctor view patient medical details
    path('doctor/add-note/<int:symptom_id>/', views.add_doctor_note, name='add-doctor-note'),#doctor add note to patient symptom
    path("check-interaction/", check_drug_interaction, name="check_drug_interaction"),#check drug interaction
    path('analyze-drug/', analyze_drug, name='analyze-drug'),#analyze drug based on patient symptoms and history
    path('gene-upload/', GeneUploadView.as_view(), name='gene-upload'),#upload gene expression file for prediction
    path('gene-reports/', GeneReportListView.as_view(), name='gene-reports'),#list gene prediction reports for patient

    path('doctor/dashboard-stats/', views.doctor_dashboard_stats),#doctor dashboard stats
    path('doctor/pending-patients/', views.doctor_pending_patients),#doctor view pending patients
    
    path('get-user-risk/<int:user_id>/', views.get_user_risk, name='get_user_risk'),#get user risk percentage based on gene expression
    path("evaluate/", evaluate),#evaluate drug effectiveness based on patient symptoms and history
    path('predict_xai/', ml_api.views.predict_xai, name='predict_xai'),#predict with xai and save to database
    path("save-report/",save_report),#save xai report to database
    path('patient/assigned-doctors/', views.get_assigned_doctors, name='get_assigned_doctors'),#patient view assigned doctors
    path("mri-predict-gradcam/", mri_predict_gradcam, name="mri_predict_gradcam"),#predict mri with gradcam visualization
    path("twin/upload-gene-file/", views.upload_gene_file, name="twin-upload-gene-file"),#upload gene expression file for twin simulation
    path("twin/run/", views.run_twin, name="run-twin"),#run twin simulation with selected drugs and gene expression data
    path("twin/history/", views.get_twin_history, name="twin-history"),#view past twin runs and results
    #path('notifications/', views.get_notifications),
    path('save-fcm-token/', views.save_fcm_token),#save fcm token for push notifications
     path(
    'request-report-permission/',
    request_report_permission,
    name='request-report-permission',
),
    path('approve-report-permission/', approve_report_permission),
path(
    'pending-report-permissions/',
     pending_report_permissions,
    name='pending-report-permissions'
),
]



urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

