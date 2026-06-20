# Standard library imports
import json
import os
import traceback
import uuid
import zipfile
from io import TextIOWrapper

# Third-party imports
import joblib
import matplotlib
import numpy as np
import pandas as pd
import shap
import torch
import torch.nn as nn
import torch.nn.functional as F
import torchvision.models as models
from firebase_admin import messaging
from xgboost import XGBClassifier

# Django imports
from django.conf import settings
from django.contrib.auth import get_user_model
from django.db.models import Q
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from matplotlib import pyplot as plt
# Django REST Framework imports
from rest_framework import generics, status, views, viewsets
from rest_framework.decorators import (
    api_view,
    authentication_classes,
    permission_classes,
)
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework_simplejwt.tokens import RefreshToken

# Local imports
from . import firebase_admin
from .models import (
    DoctorPatient,
    DrugInteraction,
    FileUpload,
    GeneExpressionFile,
    GenePredictionReport,
    GeneReportPermissionRequest,
    MedicalTestResult,
    Medicine,
    Notification,
    SymptomReport,
    TwinRun,
    TwinSimulationReport,
    User,
)
from .serializers import (
    GeneReportSerializer,
    MedicalTestResultSerializer,
    MedicineSerializer,
    PatientSerializer,
    SymptomReportSerializer,
    UserSerializer,
)
from .services import MLService
from .twin_runner import clean_for_json, run_twin_runtime_for_user
from django.utils import timezone
matplotlib.use("Agg")

print("\n\n🔥 RELOADING VIEWS.PY - IF YOU SEE THIS, THE NEW CODE IS ACTIVE! 🔥\n\n")

#from api.services.digital_twin.runner import run_full_twin_pipeline_for_user
#from api.twin_runner import run_full_twin_pipeline_for_user

#from runner import run_full_twin_pipeline_for_user
#from .twin_runner import run_twin_runtime_for_user
print("\n\n🔥 RELOADING VIEWS.PY - IF YOU SEE THIS, THE NEW CODE IS ACTIVE! 🔥\n\n")


# --- Helper: JWT Token Generation ---
def get_tokens_for_user(user):
    """Generates an access token for a specific user."""
    refresh = RefreshToken.for_user(user)
    return {
        'refresh': str(refresh),
        'access': str(refresh.access_token),
    }

# --- API Root ---
@api_view(['GET'])
@permission_classes([AllowAny])
def api_root(request):
    return JsonResponse({"message": "GENEX API is running"})

# --- Authentication Views ---

@api_view(['POST'])
@permission_classes([AllowAny])
def signup(request):
    """Handles User registration and returns a JWT token."""
    data = request.data
    email = data.get('email')
    password = data.get('password')
    name = data.get('name')

    if not email or not password or not name:
        return Response(
            {"error": "Email, password, and name are required"},
            status=status.HTTP_400_BAD_REQUEST
        )

    if User.objects.filter(username=email).exists():
        return Response(
            {"error": "User with this email already exists"},
            status=status.HTTP_400_BAD_REQUEST
        )

    # Create user with all optional profile fields
    user = User.objects.create_user(
        username=email,
        email=email,
        password=password,
        first_name=name,
        role=data.get('role', 'patient'),
        age=data.get('age'),
        gender=data.get('gender'),
        height=data.get('height'),
        weight=data.get('weight'),
    )

    tokens = get_tokens_for_user(user)
    return Response({
        "token": tokens['access'],
        "refresh": tokens['refresh'],
        "user": UserSerializer(user).data
    }, status=status.HTTP_201_CREATED)


@api_view(['POST'])
@permission_classes([AllowAny])
def signin(request):
    """Authenticates user and returns JWT token."""
    username = request.data.get('username')
    password = request.data.get('password')
    
    print(f"📥 Input Username: '{username}'")

    if not username or not password:
        return Response(
            {"error": "Username and password are required"},
            status=status.HTTP_400_BAD_REQUEST
        )

    try:
        user = User.objects.get(username=username)
    except User.DoesNotExist:
        return Response({"error": "Invalid credentials"}, status=status.HTTP_401_UNAUTHORIZED)

    if not user.check_password(password):
        return Response({"error": "Invalid credentials"}, status=status.HTTP_401_UNAUTHORIZED)

    print("✅ Login Successful! Generating token...")
    tokens = get_tokens_for_user(user)
    return Response({
        "access": tokens['access'],  # Standard SimpleJWT Key
        "token": tokens['access'],   # Kept for backward compatibility
        "user": UserSerializer(user).data
    }, status=status.HTTP_200_OK)


# --- Profile Views ---

class ProfileView(views.APIView):
    """View to retrieve or update the authenticated user's profile."""
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def get(self, request):
        serializer = UserSerializer(request.user)
        return Response(serializer.data)

    def patch(self, request):
        serializer = UserSerializer(request.user, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


#---upload gene file api view---

@api_view(['POST'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def upload_gene_file(request):
    if 'file' not in request.FILES:
        return Response({"error": "No file provided"}, status=status.HTTP_400_BAD_REQUEST)

    uploaded_file = FileUpload.objects.create(
        user=request.user,
        file=request.FILES['file']
    )

    request.user.current_gene_file = uploaded_file
    request.user.save()

    return Response({
        "message": "Gene file uploaded successfully",
        "file_id": uploaded_file.id,
        "file_url": uploaded_file.file.url if uploaded_file.file else None
    }, status=status.HTTP_201_CREATED)

#--- Twin Simulation View ---

#--- Twin Simulation View ---
@api_view(['POST'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])

def run_twin(request):
    data = request.data
    drugs = request.data.get('drugs', [])

    if not drugs or not isinstance(drugs, list):
        return Response(
            {"error": "drugs must be a non-empty list"},
            status=status.HTTP_400_BAD_REQUEST
        )

    try:
        print("🧬 TWIN RUN STARTED")
        print("👤 USER:", request.user)
        print("💊 DRUGS:", drugs)

        if not getattr(request.user, "current_gene_file", None):
            return Response(
                {"error": "No active gene expression file found for this user"},
                status=status.HTTP_400_BAD_REQUEST
            )

        print("📁 CURRENT GENE FILE:", request.user.current_gene_file.file.path)

        result = run_twin_runtime_for_user(
            user=request.user,
            drugs=drugs
        )
        result = clean_for_json(result)
        print("✅ TWIN RESULT CREATED")

        saved_run = TwinRun.objects.create(
            user=request.user,
            selected_drugs=drugs,
            results=result
        )

        return Response({
            "results": " completed successfully",
            
            "baseline_risk": result.get("baseline_risk"),
            "single_results": result.get("single_results", []),
            "pair_results": result.get("pair_results", []),
            "fusion_results": result.get("fusion_results", []),
            "best_recommendation": result.get("best_recommendation"),
            "xai_summary": result.get("xai_summary"),
        }, status=status.HTTP_200_OK)

    except Exception as e:
        import traceback

        print("🔥 TWIN RUN ERROR:")
        print(traceback.format_exc())

        return Response(
            {"error": f"Full Digital Twin pipeline failed: {str(e)}"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
# def run_twin(request):
#     drugs = request.data.get('drugs', [])

#     if not drugs or not isinstance(drugs, list):
#         return Response(
#             {"error": "drugs must be a non-empty list"},
#             status=status.HTTP_400_BAD_REQUEST
#         )

#     if not request.user.current_gene_file:
#         return Response(
#             {"error": "No active gene expression file found for this user"},
#             status=status.HTTP_400_BAD_REQUEST
#         )

#     gene_file_path = request.user.current_gene_file.file.path

#     try:
#         result = run_twin_simulation(
#             gene_file_path=gene_file_path,
#             drugs=drugs
#         )

#         saved_run = TwinRun.objects.create(
#             user=request.user,
#             selected_drugs=drugs,
#             results=result
#         )

#         return Response({
#             "message": "Twin simulation completed successfully",
#             "run_id": saved_run.id,
#             "result": result
#         }, status=status.HTTP_200_OK)

#     except Exception as e:
#         return Response(
#             {"error": f"Twin simulation failed: {str(e)}"},
#             status=status.HTTP_500_INTERNAL_SERVER_ERROR
#         )

#---History API View---
@api_view(['GET'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def get_twin_history(request):
    runs = TwinRun.objects.filter(user=request.user).order_by('-created_at')

    data = []
    for run in runs:
        data.append({
            "id": run.id,
            "selected_drugs": run.selected_drugs,
            "results": run.results,
            "created_at": run.created_at
        })

    return Response(data, status=status.HTTP_200_OK)

# --- Medicine Views ---f

class MedicineViewSet(viewsets.ModelViewSet):
    """Handles List, Create, and Delete for Patient Medicines."""
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]
    serializer_class = MedicineSerializer

    def get_queryset(self):
        return Medicine.objects.filter(user=self.request.user).order_by('-added_at')

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class SymptomViewSet(viewsets.ModelViewSet):
    """Handles List and Create for Patient Symptoms."""
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]
    serializer_class = SymptomReportSerializer

    def get_queryset(self):
        return SymptomReport.objects.filter(user=self.request.user).order_by('-created_at')

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


# --- Doctor / Patient Interaction Views ---

class PatientSearchView(generics.ListAPIView):
    """API View specifically for searching patients."""
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated] 
    serializer_class = PatientSerializer

    def get_queryset(self):
        queryset = User.objects.filter(role='patient')
        search_query = self.request.query_params.get('query', None)
        if search_query:
            queryset = queryset.filter(username__icontains=search_query)
        return queryset


@api_view(['POST'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def send_patient_request(request):
    """Allows a Doctor to send a connection request to a Patient."""
    print("--- NEW REQUEST RECEIVED ---")

    doctor_user = request.user
    patient_username = request.data.get('patient_username')

    if not patient_username:
        return Response(
            {'error': 'Patient username is required'},
            status=status.HTTP_400_BAD_REQUEST
        )

    if DoctorPatient.objects.filter(
        doctor_username=doctor_user.username,
        patient_username__iexact=patient_username
    ).exists():
        return Response(
            {'message': 'Request already exists'},
            status=status.HTTP_400_BAD_REQUEST
        )
    try:
        DoctorPatient.objects.create(
            doctor_username=doctor_user.username,
            patient_username=patient_username,
            status='pending'
        )

        patient_user = User.objects.get(
            username__iexact=patient_username
        )

        print("PATIENT FOUND:", patient_user.username)
        print("PATIENT FCM TOKEN:", patient_user.fcm_token)

        if patient_user.fcm_token:
            try:
                message = messaging.Message(
                    notification=messaging.Notification(
                        title="New Doctor Request",
                        body=f"Dr. {doctor_user.username} wants to connect with you.",
                    ),
                    token=patient_user.fcm_token,
                )

                response = messaging.send(message)

                print("FCM SENT SUCCESSFULLY:", response)

            except Exception as fcm_error:
                print("FCM SEND ERROR:", str(fcm_error))

        else:
            print("NO FCM TOKEN FOUND FOR PATIENT")

        print(
            f"SUCCESS: Linked Doctor {doctor_user.username} with Patient {patient_username}"
        )

        return Response(
            {'message': 'Request sent successfully'},
            status=status.HTTP_201_CREATED
        )

    except Exception as e:
        print("GENERAL ERROR:", str(e))

        return Response(
            {'error': str(e)},
            status=status.HTTP_400_BAD_REQUEST
        )

@api_view(['GET'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def get_patient_requests(request):
    current_user = request.user.username

    my_requests = DoctorPatient.objects.filter(
        patient_username__iexact=current_user
    ).order_by('-id')

    data = []

    for req in my_requests:
        data.append({
            "id": req.id,
            "doctor_name": req.doctor_username,
            "status": req.status,
            "date": "Today",
        })

    return Response(data, status=status.HTTP_200_OK)


@api_view(['POST'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def update_request_status(request, request_id):
    """Allows Patient to Accept/Reject a request."""
    user_email = request.user.username
    
    try:
        # Find the request AND ensure it belongs to this patient
        connection = DoctorPatient.objects.get(
            id=request_id, 
            patient_username__iexact=user_email
        )
    except DoctorPatient.DoesNotExist:
        return Response({"error": "Request not found"}, status=status.HTTP_404_NOT_FOUND)

    action = request.data.get('action') # 'accept' or 'reject'

    if action == 'accept':
        connection.status = 'accepted'
    elif action == 'reject':
        connection.status = 'rejected'
    else:
        return Response({"error": "Invalid action"}, status=status.HTTP_400_BAD_REQUEST)

    connection.save()
    return Response({"message": f"Request {action}ed successfully", "status": connection.status})
# --- Doctor Dashboard Views ---

@api_view(['GET'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def get_my_patients(request):
    print("\n========== 👨‍⚕️ DOCTOR DEBUG MODE ==========")
    
    # 1. Who is asking?
    current_doctor = request.user.username
    print(f"🩺 LOGGED IN AS: '{current_doctor}'")

    # 2. What is in the database? (Print EVERYTHING)
    all_connections = DoctorPatient.objects.all()
    print(f"📦 TOTAL CONNECTIONS IN DB: {all_connections.count()}")

    found_any = False
    
    for c in all_connections:
        print(f"   -> ID {c.id}: Doctor='{c.doctor_username}' | Patient='{c.patient_username}' | Status='{c.status}'")
        
        # Check strict match
        if c.doctor_username == current_doctor:
            print("      ✅ STRICT MATCH: Doctor username matches exactly.")
            if c.status == 'accepted':
                 print("      🎉 STATUS MATCH: This should appear in your list!")
                 found_any = True
            else:
                 print(f"      ⚠️ STATUS MISMATCH: Status is '{c.status}', not 'accepted'.")
        
        # Check case-insensitive match (The likely fix)
        elif c.doctor_username.lower() == current_doctor.lower():
            print("      ⚠️ CASE MISMATCH: Names match but capitalization is different.")
            if c.status == 'accepted':
                 found_any = True

    # 3. actually filter using the robust method (Case Insensitive)
    connections = DoctorPatient.objects.filter(
        doctor_username__iexact=current_doctor, # Fixes capitalization issues
        status='accepted'
    )
    
    print(f"📉 FINAL QUERY RESULT: Found {connections.count()} patients.")

    # 4. Get the patient details
    patient_usernames = [c.patient_username for c in connections]
    patients = User.objects.filter(username__in=patient_usernames)

    data = []
    for p in patients:
        data.append({
            "id": p.id,  # <--- THIS WAS MISSING! CRITICAL FIX.
            "name": p.first_name if p.first_name else p.username, # Fallback if name is empty
            "email": p.username,
            "age": p.age,
            "gender": p.gender,
            "weight": p.weight,
            "height": p.height,
        })

    return Response(data, status=status.HTTP_200_OK)
# --- Doctor: View Patient Records ---

@api_view(['GET'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def get_patient_medical_details(request, patient_id):
    doctor_username = request.user.username

    try:
        # 1. Get the Patient
        target_patient = User.objects.get(id=patient_id)

        # 2. Check Permission
        has_access = DoctorPatient.objects.filter(
            doctor_username=doctor_username,
            patient_username=target_patient.username,
            status='accepted'
        ).exists()

        if not has_access:
            return Response(
                {"error": "Access Denied"},
                status=status.HTTP_403_FORBIDDEN
            )

        # 3. Fetch Medicines
        medicines = Medicine.objects.filter(user=target_patient).values()

        # 4. Fetch Symptoms
        raw_symptoms = SymptomReport.objects.filter(
            user=target_patient
        ).order_by('-created_at')

        print(f"🔍 FOUND {raw_symptoms.count()} SYMPTOMS FOR {target_patient.username}")

        symptoms_data = []
        for s in raw_symptoms:
            symptoms_data.append({
                "id": s.id,
                "symptom": s.symptom_name,
                "symptom_name": s.symptom_name,
                "severity": s.severity,
                "frequency": s.frequency,
                "notes": s.notes,
                "created_at": s.created_at,
            })

        # 5. Fetch Medical Test Results
        raw_test_results = MedicalTestResult.objects.filter(
            user=target_patient
        ).order_by('-created_at')

        print(f"🧪 FOUND {raw_test_results.count()} TEST RESULTS FOR {target_patient.username}")

        test_results_data = []
        for t in raw_test_results:
            test_results_data.append({
                "id": t.id,
                "age": t.age,
                "gender": t.gender,
                "esr": t.esr,
                "crp": t.crp,
                "rf": t.rf,
                "anti_ccp": t.anti_ccp,
                "c3": t.c3,
                "c4": t.c4,
                "ana": t.ana,
                "anti_sm": t.anti_sm,
                "anti_ro": t.anti_ro,
                "hla_b27": t.hla_b27,
                "anti_la": t.anti_la,
                "anti_dsdna": t.anti_dsdna,
                "disease_prediction": t.disease_prediction,
                "confidence": t.confidence,
                "xai_explanation": t.xai_explanation,
                "created_at": t.created_at,
            })

        # 6. Fetch Gene Prediction Reports
        raw_gene_reports = GenePredictionReport.objects.filter(
            patient=target_patient
        ).order_by('-created_at')

        print(f"🧬 FOUND {raw_gene_reports.count()} GENE REPORTS FOR {target_patient.username}")

        gene_reports_data = []
        for g in raw_gene_reports:
            gene_reports_data.append({
                "id": g.id,
                "risk_percentage": g.risk_percentage,
                "result_label": g.result_label,
                "file_name": g.file_name,
                "created_at": g.created_at,
                "precision": g.precision,
                "recall": g.recall,
                "f1_score": g.f1_score,
                "confidence_interval": g.confidence_interval,
                "top_affecting_genes": g.top_affecting_genes,
                "input_features": g.input_features,
            })

        return Response({
            "patient_name": target_patient.first_name,
            "medicines": list(medicines),
            "symptoms": symptoms_data,
            "test_results": test_results_data,
            "gene_prediction_reports": gene_reports_data,
        }, status=status.HTTP_200_OK)

    except User.DoesNotExist:
        return Response(
            {"error": "Patient not found"},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        print(f"❌ SERVER ERROR: {str(e)}")
        return Response(
            {"error": str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['POST'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def add_doctor_note(request, symptom_id):
    """Appends a Doctor's note to a specific Symptom Report."""
    try:
        # 1. Find the specific symptom report
        report = SymptomReport.objects.get(id=symptom_id)
        
        # 2. Get the note from the doctor
        doctor_note = request.data.get('note')
        if not doctor_note:
            return Response({"error": "Note cannot be empty"}, status=status.HTTP_400_BAD_REQUEST)

        # 3. Append to existing notes (Safe way, preserves patient's text)
        original_notes = report.notes if report.notes else ""
        
        # Format: "Original Text" + "--- Doctor: New Text"
        updated_notes = f"{original_notes}\n\n Doctor: {doctor_note}".strip()
        
        report.notes = updated_notes
        report.save()

        return Response({
            "message": "Note saved successfully", 
            "new_notes": updated_notes
        }, status=status.HTTP_200_OK)

    except SymptomReport.DoesNotExist:
        return Response({"error": "Symptom not found"}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
@csrf_exempt
def check_drug_interaction(request):
    if request.method != "POST":
        return JsonResponse({"error": "Only POST allowed"}, status=405)

    try:
        data = json.loads(request.body)
        drug1 = data.get("drug1", "").strip()
        drug2 = data.get("drug2", "").strip()

        interaction = DrugInteraction.objects.filter(
            (Q(drug_1__icontains=drug1) & Q(drug_2__icontains=drug2)) |
            (Q(drug_1__icontains=drug2) & Q(drug_2__icontains=drug1))
        ).first()

        if interaction:
            return JsonResponse({
                "found": True,
                "description": interaction.interaction_description
            })

        return JsonResponse({
            "found": False,
            "message": "No interaction found"
        })

    except Exception as e:
        return JsonResponse({"error": str(e)})
    
# api/views.py
import json
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status

from .models import GeneExpressionFile

@api_view(['POST'])
@permission_classes([AllowAny])
def analyze_drug(request):
    try:
        user_id = request.data.get("user_id")
        drug = request.data.get("drug")

        if not user_id:
            return Response({"error": "user_id is required."}, status=400)

        if not drug:
            return Response({"error": "drug is required."}, status=400)

        gene_file = (
            GeneExpressionFile.objects
            .filter(user_id=user_id)
            .order_by("-uploaded_at")
            .first()
        )

        if not gene_file:
            return Response({"error": "No gene expression file found."}, status=404)

        file_path = str(gene_file.file)

        result = analyze_drug_with_file(drug=drug, file_path=file_path)

        return Response({
            "drug": result.get("drug", drug),
            "combined_score": result.get("combined_score"),
            "rank_score": result.get("rank_score"),
            "ic50": result.get("ic50"),
            "twin_reduction": result.get("twin_reduction"),
            "best_model": result.get("best_model", "Unknown"),
            "marker_x": result.get("marker_x", 170),
            "marker_y": result.get("marker_y", 220),
            "message": result.get("message", ""),
            "file_used": file_path,
        })

    except Exception as e:
        return Response({"error": f"Unexpected server error: {str(e)}"}, status=500)
    
print("BEFORE loading model", flush=True)


MODEL = joblib.load('api/ml_asssets/best_ra_xgb_model.joblib')
FEATURES = joblib.load('api/ml_asssets/gene_features.joblib')
class GeneUploadView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def post(self, request):
        file = request.FILES.get("file")

        if not file:
            return Response(
                {"error": "No file uploaded"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Optional: restrict upload type
        if not file.name.lower().endswith(".csv"):
            return Response(
                {"error": "Only CSV files are supported"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            # 1) Read CSV
            text_file = TextIOWrapper(file.file, encoding="utf-8")
            df = pd.read_csv(text_file, sep=",")

            # 2) Convert everything to numeric
            df = df.apply(pd.to_numeric, errors="coerce").fillna(0)

            if df.empty:
                return Response(
                    {"error": "Uploaded file is empty after preprocessing"},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            # 3) Keep only first row
            # Remove this if you want batch prediction later
            df = df.iloc[[0]].copy()

            # 4) Align exactly to training features
            df = df.reindex(columns=FEATURES, fill_value=0)

            # 5) Validate final shape/order
            if list(df.columns) != list(FEATURES):
                return Response(
                    {"error": "Uploaded gene expression file does not match model features"},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            # 6) Apply same transform used in training
            df_log = np.log2(df + 1)

            # 7) Convert to model input
            X = df_log.to_numpy()

            print("--- PREDICTION DEBUG ---")
            print(f"User: {request.user}")
            print(f"File: {file.name}")
            print(f"Shape: {X.shape}")
            print(f"Mean expression value: {X.mean()}")
            print(f"Max expression value: {X.max()}")
            print(f"Number of non-zero features: {np.count_nonzero(X)}")

            # 8) Predict
            probability = float(MODEL.predict_proba(X)[0][1])
            risk_score = round(probability * 100, 2)
            result_label = "High Risk" if risk_score > 50 else "Low Risk"

            # 9) Save aligned input features as JSON-serializable dict
            input_features = {
                str(col): float(val)
                for col, val in df_log.iloc[0].to_dict().items()
            }

            # 10) Compute top affecting genes with SHAP
            top_affecting_genes = {}
            try:
                explainer = shap.TreeExplainer(MODEL)
                shap_values = explainer.shap_values(df_log)

                if isinstance(shap_values, list):
                    sample_shap = shap_values[1][0]
                else:
                    # Handles array output directly
                    sample_shap = shap_values[0]

                shap_map = dict(zip(df_log.columns, sample_shap))
                top_items = sorted(
                    shap_map.items(),
                    key=lambda x: abs(x[1]),
                    reverse=True,
                )[:10]

                top_affecting_genes = {
                    str(gene): float(value) for gene, value in top_items
                }

            except Exception as shap_error:
                print("SHAP ERROR:", str(shap_error))
                top_affecting_genes = {}

            # 11) Optional model-level metrics
            precision = None
            recall = None
            f1_score = None
            confidence_interval = None

            # 12) Save report
            report = GenePredictionReport.objects.create(
                patient=request.user,
                risk_percentage=risk_score,
                result_label=result_label,
                file_name=file.name,
                precision=precision,
                recall=recall,
                f1_score=f1_score,
                confidence_interval=confidence_interval,
                top_affecting_genes=top_affecting_genes,
                input_features=input_features,
            )

            return Response(
                {
                    "percentage": report.risk_percentage,
                    "label": report.result_label,
                    "report_id": report.id,
                    "filename": report.file_name,
                    "date": report.created_at,
                    "top_affecting_genes": report.top_affecting_genes,
                },
                status=status.HTTP_200_OK,
            )

        except Exception as e:
            print("GENE UPLOAD ERROR:", str(e))
            return Response(
                {"error": f"Gene processing/prediction failed: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )




@api_view(["GET"])
@permission_classes([IsAuthenticated])
def doctor_dashboard_stats(request):
    doctor_username = request.user.username

    assigned_count = DoctorPatient.objects.filter(
        doctor_username=doctor_username,
        status="accepted",
    ).count()

    pending_count = DoctorPatient.objects.filter(
        doctor_username=doctor_username,
        status="pending",
    ).count()

    return Response({
        "assigned_patients": assigned_count,
        "pending_patients": pending_count,
    })


User = get_user_model()


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def doctor_pending_patients(request):
    doctor_username = request.user.username

    pending_links = DoctorPatient.objects.filter(
        doctor_username=doctor_username,
        status="pending",
    )

    patients_data = []

    for link in pending_links:
        patient_info = {
            "id": None,
            "username": link.patient_username,
            "email": link.patient_username,
            "appointment_date": link.appointment_date,
            "status": link.status,
            "first_name": "",
            "last_name": "",
        }

        user = User.objects.filter(username=link.patient_username).first()
        if user:
            patient_info["id"] = user.id
            patient_info["email"] = getattr(user, "email", link.patient_username) or link.patient_username
            patient_info["first_name"] = getattr(user, "first_name", "")
            patient_info["last_name"] = getattr(user, "last_name", "")

        patients_data.append(patient_info)

    return Response({
        "count": len(patients_data),
        "patients": patients_data,
    })


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def get_user_risk(request, user_id):
    try:
        prediction = GenePredictionReport.objects.filter(
            patient_id=user_id
        ).latest("created_at")

        return JsonResponse({
            "status": "success",
            "risk_percentage": prediction.risk_percentage,
        })

    except GenePredictionReport.DoesNotExist:
        return JsonResponse(
            {"status": "error", "message": "No data found for this patient"},
            status=404,
        )




@csrf_exempt
def evaluate(request):
    if request.method == "GET":
        return JsonResponse({
            "message": "API is working. Use POST with file + drug1 + optional drug2."
        })

    if request.method == "POST":
        file = request.FILES.get("file")
        drug1 = request.POST.get("drug1")
        drug2 = request.POST.get("drug2")

        if file is None:
            return JsonResponse({"error": "file required"}, status=400)

        try:
            patient_df = pd.read_csv(file)

            result = ml_service.evaluate(#benrooh ll services.py hnla2y class esmo MLService w feha function evaluate l feha ba el functionality
                drug1=drug1,
                drug2=drug2,
                patient_df=patient_df,
            )

            return JsonResponse(result)

        except Exception as e:
            print("EVALUATE ERROR:", str(e))
            return JsonResponse({"error": str(e)}, status=500)

    return JsonResponse({"error": "Method not allowed"}, status=405)


class GeneReportListView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def get(self, request):
        reports = GenePredictionReport.objects.filter(
            patient=request.user
        ).order_by("-created_at")

        serializer = GeneReportSerializer(reports, many=True)
        return Response(serializer.data)


@api_view(["POST"])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def save_report(request):
    try:
        data = request.data
        report = data.get("report_data") or {}
        best = report.get("best_recommendation") or {}

        if "drug_pair" in best:
            best_drug = " + ".join(best["drug_pair"])
        else:
            best_drug = best.get("drug") or "NO_SAFE_DRUG"
            risk_reduction = best.get("risk_reduction", 0)

        saved = TwinSimulationReport.objects.create(
            user=request.user,
            drug1=data.get("drug1", ""),
            drug2=data.get("drug2", ""),
            file_name=data.get("file_name", ""),
            best_drug=best_drug,
            risk_reduction=risk_reduction,
            full_report=report,
        )

        return JsonResponse({
            "status": "success",
            "report_id": saved.id,
        })

    except Exception as e:
        print("🔥 SAVE REPORT ERROR:", str(e))
        return JsonResponse({"error": str(e)}, status=500)
    


@api_view(['GET'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def get_assigned_doctors(request):
    user = request.user

    doctor_links = DoctorPatient.objects.filter(
        patient_username=user.username,
        status='accepted'
    )

    doctors_data = []
    for link in doctor_links:
        try:
            doctor = User.objects.get(username=link.doctor_username)
            doctors_data.append({
                "doctor_id": doctor.id,
                "doctor_username": doctor.username,
                "doctor_name": getattr(doctor, 'full_name', doctor.username),
            })
        except User.DoesNotExist:
            continue

    return Response(doctors_data, status=status.HTTP_200_OK)









device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
THRESHOLD = 0.55


class MRNetFastModel(nn.Module):
    def __init__(self):
        super().__init__()

        backbone = models.resnet18(weights=None)
        self.encoder = nn.Sequential(*list(backbone.children())[:-1])
        self.feature_dim = 512

        self.classifier = nn.Sequential(
            nn.Linear(self.feature_dim * 3, 256),
            nn.ReLU(),
            nn.Dropout(0.3),
            nn.Linear(256, 1)
        )

    def encode(self, x):
        B, S, C, H, W = x.shape
        x = x.view(B * S, C, H, W)
        x = self.encoder(x)
        x = x.view(B, S, -1)
        x, _ = torch.max(x, dim=1)
        return x

    def forward(self, axial, coronal, sagittal):
        a = self.encode(axial)
        c = self.encode(coronal)
        s = self.encode(sagittal)

        x = torch.cat([a, c, s], dim=1)
        return self.classifier(x).squeeze(1)


MODEL_PATH = os.path.join(settings.BASE_DIR, "api", "ml_asssets", "best_fast_mrnet.pth")

mri_model = MRNetFastModel().to(device)
mri_model.load_state_dict(torch.load(MODEL_PATH, map_location=device))
mri_model.eval()


def preprocess_mri(exam, image_size=(224, 224), num_slices=16):

    exam = exam.astype(np.float32)

    # normalize
    exam = (exam - exam.min()) / (exam.max() - exam.min() + 1e-8)

    # ensure enough slices
    if len(exam) >= num_slices:
        start = (len(exam) - num_slices) // 2
        exam = exam[start:start + num_slices]
    else:
        pad = num_slices - len(exam)
        exam = np.pad(
            exam,
            ((0, pad), (0, 0), (0, 0)),
            mode='constant'
        )

    processed = []

    for sl in exam:

        # slice shape should be [H, W]
        sl = torch.tensor(sl, dtype=torch.float32)

        print("SLICE SHAPE:", sl.shape)

        # make [1,1,H,W]
        sl = sl.unsqueeze(0).unsqueeze(0)

        print("BEFORE INTERPOLATE:", sl.shape)

        # resize
        sl = F.interpolate(
            sl,
            size=(224, 224),
            mode="bilinear",
            align_corners=False
        )

        print("AFTER INTERPOLATE:", sl.shape)

        # remove batch dim
        sl = sl.squeeze(0)

        # grayscale -> RGB
        sl = sl.repeat(3, 1, 1)

        processed.append(sl)

    return torch.stack(processed)

class GradCAM:
    def __init__(self, model):
        self.model = model
        self.target_layer = self.model.encoder[7]
        self.activations = []
        self.gradients = []
        self.hook = self.target_layer.register_forward_hook(self._forward_hook)

    def _forward_hook(self, module, input, output):
        idx = len(self.activations)
        self.activations.append(output)
        self.gradients.append(None)
        output.register_hook(lambda grad, idx=idx: self._save_gradient(idx, grad))

    def _save_gradient(self, idx, grad):
        self.gradients[idx] = grad

    def remove_hooks(self):
        self.hook.remove()

    def generate(self, axial, coronal, sagittal, plane="axial", slice_idx=8):
        self.activations = []
        self.gradients = []

        axial = axial.unsqueeze(0).to(device)
        coronal = coronal.unsqueeze(0).to(device)
        sagittal = sagittal.unsqueeze(0).to(device)

        self.model.zero_grad()

        logit = self.model(axial, coronal, sagittal)
        prob = torch.sigmoid(logit)[0].item()

        score = logit[0] if prob >= THRESHOLD else -logit[0]
        score.backward()

        plane_index = {"axial": 0, "coronal": 1, "sagittal": 2}[plane]

        activation = self.activations[plane_index]
        gradient = self.gradients[plane_index]

        weights = gradient.mean(dim=(2, 3), keepdim=True)
        cam = (weights * activation).sum(dim=1).squeeze()

        cam = F.relu(cam)
        cam = cam - cam.min()
        cam = cam / (cam.max() + 1e-8)

        return cam.detach().cpu(), prob


def save_gradcam_images(axial, coronal, sagittal):
    gradcam = GradCAM(mri_model)

    results = {}
    planes = {
        "axial": axial,
        "coronal": coronal,
        "sagittal": sagittal,
    }

    for plane, tensor in planes.items():
        slice_idx = tensor.shape[0] // 2

        cam, prob = gradcam.generate(
            axial,
            coronal,
            sagittal,
            plane=plane,
            slice_idx=slice_idx
        )

        image = tensor[slice_idx, 0].cpu().numpy()
        image = image - image.min()
        image = image / (image.max() + 1e-8)

        if cam.dim() == 3:
            cam = cam[slice_idx]

        cam = cam.unsqueeze(0).unsqueeze(0)

        cam_resized = F.interpolate(
            cam,
            size=image.shape,
            mode="bilinear",
            align_corners=False
        ).squeeze().numpy()

        filename = f"gradcam_{plane}_{uuid.uuid4().hex}.png"
        gradcam_dir = os.path.join(settings.MEDIA_ROOT, "gradcam")
        os.makedirs(gradcam_dir, exist_ok=True)

        save_path = os.path.join(gradcam_dir, filename)

        plt.figure(figsize=(4, 4))
        plt.imshow(image, cmap="gray")
        plt.imshow(cam_resized, cmap="jet", alpha=0.45)
        plt.axis("off")
        plt.tight_layout()
        plt.savefig(save_path, bbox_inches="tight", pad_inches=0, dpi=100)
        plt.close()

        results[plane] = f"{settings.MEDIA_URL}gradcam/{filename}"

    gradcam.remove_hooks()

    return results, prob

@api_view(["POST"])
@permission_classes([IsAuthenticated])
def mri_predict_gradcam(request):
    try:
        uploaded_file = request.FILES.get("file")

        if uploaded_file is None:
            return JsonResponse({"error": "No MRI file uploaded."}, status=400)

        temp_dir = os.path.join(settings.MEDIA_ROOT, "temp_mri")
        os.makedirs(temp_dir, exist_ok=True)

        zip_path = os.path.join(temp_dir, uploaded_file.name)

        with open(zip_path, "wb+") as destination:
            for chunk in uploaded_file.chunks():
                destination.write(chunk)

        extract_dir = os.path.join(temp_dir, uuid.uuid4().hex)
        os.makedirs(extract_dir, exist_ok=True)

        with zipfile.ZipFile(zip_path, "r") as zip_ref:
            zip_ref.extractall(extract_dir)

        axial_path = os.path.join(extract_dir, "axial.npy")
        coronal_path = os.path.join(extract_dir, "coronal.npy")
        sagittal_path = os.path.join(extract_dir, "sagittal.npy")

        if not all(os.path.exists(p) for p in [axial_path, coronal_path, sagittal_path]):
            return JsonResponse({
                "error": "ZIP must contain axial.npy, coronal.npy, and sagittal.npy."
            }, status=400)

        axial = preprocess_mri(np.load(axial_path))
        coronal = preprocess_mri(np.load(coronal_path))
        sagittal = preprocess_mri(np.load(sagittal_path))

        gradcam_urls, risk_score = save_gradcam_images(axial, coronal, sagittal)
        prediction = "Abnormal" if risk_score >= THRESHOLD else "Normal"

        return JsonResponse({
         "risk_score": risk_score,
        "prediction": prediction,
        "gradcam_urls": {
        "axial": request.build_absolute_uri(gradcam_urls["axial"]),
        "coronal": request.build_absolute_uri(gradcam_urls["coronal"]),
        "sagittal": request.build_absolute_uri(gradcam_urls["sagittal"]),
    },
    "explanation": "The Grad-CAM images highlight the MRI regions that most influenced the abnormality prediction across axial, coronal, and sagittal views."
})

    except Exception as e:
        print("MRI ERROR:")
        traceback.print_exc()

        return JsonResponse({
            "error": str(e)
        }, status=500)

@api_view(['POST'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def save_fcm_token(request):
    token = request.data.get("fcm_token")

    if not token:
        return Response({"error": "FCM token is required"}, status=400)

    request.user.fcm_token = token
    request.user.save()

    return Response({"message": "FCM token saved successfully"})

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def request_report_permission(request):
    report_id = request.data.get('report_id')
    doctor_id = request.data.get('doctor_id')

    report = GenePredictionReport.objects.get(id=report_id)
    doctor = User.objects.get(id=doctor_id)

    GeneReportPermissionRequest.objects.create(
        report=report,
        patient=request.user,
        doctor=doctor,
        status='pending'
    )

    return Response({"message": "Permission request sent"})


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def approve_report_permission(request):
    report_id = request.data.get('report_id')

    if request.user.role != 'doctor':
        return Response(
            {"error": "Only doctors can approve report access"},
            status=status.HTTP_403_FORBIDDEN
        )

    if not report_id:
        return Response(
            {"error": "report_id is required"},
            status=status.HTTP_400_BAD_REQUEST
        )

    try:
        permission_request = GeneReportPermissionRequest.objects.filter(
            report_id=report_id,
            doctor=request.user,
            status='pending'
        ).latest('requested_at')

        permission_request.status = 'approved'
        permission_request.responded_at = timezone.now()
        permission_request.save()

        return Response(
            {
                "message": "Report access approved successfully",
                "status": "approved"
            },
            status=status.HTTP_200_OK
        )

    except GeneReportPermissionRequest.DoesNotExist:
        return Response(
            {"error": "No pending permission request found for this report"},
            status=status.HTTP_404_NOT_FOUND
        )
        
    
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def pending_report_permissions(request):
    if request.user.role != 'doctor':
        return Response(
            {"error": "Only doctors can view pending requests"},
            status=403
        )

    requests = GeneReportPermissionRequest.objects.filter(
        doctor=request.user,
        status='pending'
    ).order_by('-requested_at')

    data = []

    for req in requests:
        data.append({
            "id": req.id,
            "report_id": req.report.id,
            "patient_id": req.patient.id,
            "patient_username": req.patient.username,
            "status": req.status,
            "requested_at": req.requested_at,
        })

    return Response(data)