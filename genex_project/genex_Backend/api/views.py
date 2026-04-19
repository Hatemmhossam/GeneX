from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.db.models import Q
from rest_framework import status, views, viewsets, generics 
from rest_framework.response import Response

from rest_framework.decorators import api_view, permission_classes, authentication_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.authentication import JWTAuthentication
from .services import MLService


from .models import User, Medicine, SymptomReport,TwinSimulationReport
from .serializers import UserSerializer, MedicineSerializer, SymptomReportSerializer,MedicalTestResultSerializer

from django.db import connection
from rest_framework.parsers import MultiPartParser, FormParser
from django.views.decorators.csrf import csrf_exempt
# ✅ IMPORTS: Ensure all your models and serializers are here
from .models import User, Medicine, SymptomReport, DoctorPatient, FileUpload, TwinRun,MedicalTestResult
# from .serializers import (
#     UserSerializer, 
#     MedicineSerializer, 
#     SymptomReportSerializer, 
#     # PatientSerializer
# )
print("\n\n🔥 RELOADING VIEWS.PY - IF YOU SEE THIS, THE NEW CODE IS ACTIVE! 🔥\n\n")

from django.db import connection
from rest_framework.parsers import MultiPartParser, FormParser
#from .services import run_twin_simulation
# ✅ IMPORTS: Ensure all your models and serializers are here
from .models import User, Medicine, SymptomReport, DoctorPatient, FileUpload, TwinRun

from django.db import connection
from .models import DrugInteraction
import joblib
import pandas as pd
import numpy as np
from django.contrib.auth import get_user_model
from rest_framework.views import APIView
from rest_framework.response import Response
from .models import GenePredictionReport
from io import TextIOWrapper
from .models import GeneExpressionFile
#from .services.drug_analysis import analyze_drug_with_file
import json
from .models import GeneExpressionFile
# ✅ IMPORTS: Ensure all your models and serializers are here
from .models import User, Medicine, SymptomReport, DoctorPatient
import shap
from .models import GenePredictionReport

#for test 
from django.views.decorators.csrf import csrf_exempt

from .serializers import (
    UserSerializer, 
    MedicineSerializer, 
    SymptomReportSerializer, 
    PatientSerializer
)
from .serializers import GeneReportSerializer



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
@api_view(['POST'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def run_twin(request):
    drugs = request.data.get('drugs', [])

    if not drugs or not isinstance(drugs, list):
        return Response(
            {"error": "drugs must be a non-empty list"},
            status=status.HTTP_400_BAD_REQUEST
        )

    if not request.user.current_gene_file:
        return Response(
            {"error": "No active gene expression file found for this user"},
            status=status.HTTP_400_BAD_REQUEST
        )

    gene_file_path = request.user.current_gene_file.file.path

    try:
        result = run_twin_simulation(
            gene_file_path=gene_file_path,
            drugs=drugs
        )

        saved_run = TwinRun.objects.create(
            user=request.user,
            selected_drugs=drugs,
            results=result
        )

        return Response({
            "message": "Twin simulation completed successfully",
            "run_id": saved_run.id,
            "result": result
        }, status=status.HTTP_200_OK)

    except Exception as e:
        return Response(
            {"error": f"Twin simulation failed: {str(e)}"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

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
# --- Medicine Views ---

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
        return Response({'error': 'Patient username is required'}, status=status.HTTP_400_BAD_REQUEST)

    # Check if Request Already Exists
    # We use __iexact to ensure case-insensitive matching
    if DoctorPatient.objects.filter(
        doctor_username=doctor_user.username, 
        patient_username__iexact=patient_username
    ).exists():
        return Response({'message': 'Request already exists'}, status=status.HTTP_400_BAD_REQUEST)

    # Save the Request
    try:
        DoctorPatient.objects.create(
            doctor_username=doctor_user.username,
            patient_username=patient_username,
            status='pending'
        )
        print(f"SUCCESS: Linked Doctor {doctor_user.username} with Patient {patient_username}")
        return Response({'message': 'Request sent successfully'}, status=status.HTTP_201_CREATED)
    except Exception as e:
        print(f"Error saving: {e}")
        return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def get_patient_requests(request):
    print("\n========== 🕵️ NUCLEAR DEBUG MODE ==========")
    
    # 1. Who are you?
    current_user = request.user.username
    print(f"👤 YOU ARE LOGGED IN AS: '{current_user}'")

    # 2. What is in the database? (Print EVERYTHING)
    all_requests = DoctorPatient.objects.all()
    print(f"📦 TOTAL ROWS IN DB: {all_requests.count()}")
    
    for req in all_requests:
        print(f"   -> Row ID {req.id}: Patient='{req.patient_username}' | Doctor='{req.doctor_username}'")
        
        # Check if it matches manually
        if req.patient_username.lower().strip() == current_user.lower().strip():
             print("      ✅ MATCH FOUND (Python comparison)")
        else:
             print("      ❌ NO MATCH")

    # 3. actually filter
    my_requests = DoctorPatient.objects.filter(
        patient_username__iexact=current_user
    ).order_by('-id')

    print(f"📉 DJANGO FILTER FOUND: {my_requests.count()}")

    # 4. Return whatever we found
    data = []
    for req in my_requests:
        data.append({
            "id": req.id,
            "doctor_name": req.doctor_username,
            "status": req.status,
            "date": "Today"
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


ml_service = MLService()


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

            result = ml_service.evaluate(
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

        best_drug = best.get("drug", "NO_SAFE_DRUG")
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