from django.http import JsonResponse
from rest_framework import status, views, viewsets, generics 
from rest_framework.response import Response
from rest_framework.decorators import api_view, permission_classes, authentication_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.authentication import JWTAuthentication
from django.db import connection

# ✅ IMPORTS: Ensure all your models and serializers are here
from .models import User, Medicine, SymptomReport, DoctorPatient
from .serializers import (
    UserSerializer, 
    MedicineSerializer, 
    SymptomReportSerializer, 
    PatientSerializer
)
print("\n\n🔥 RELOADING VIEWS.PY - IF YOU SEE THIS, THE NEW CODE IS ACTIVE! 🔥\n\n")


import joblib
import pandas as pd
import numpy as np
from rest_framework.views import APIView
from rest_framework.response import Response
from .models import GenePredictionReport
from io import TextIOWrapper

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
            return Response({"error": "Access Denied"}, status=status.HTTP_403_FORBIDDEN)

        # 3. Fetch Medicines
        medicines = Medicine.objects.filter(user=target_patient).values()

        # 4. Fetch Symptoms
        raw_symptoms = SymptomReport.objects.filter(user=target_patient)
        
        # DEBUG PRINT: Verify count in terminal
        print(f"🔍 FOUND {raw_symptoms.count()} SYMPTOMS FOR {target_patient.username}")

        symptoms_data = []
        for s in raw_symptoms:
            symptoms_data.append({
                "id": s.id,
                # ✅ SEND BOTH KEYS so Flutter never misses it
                "symptom": s.symptom_name,       
                "symptom_name": s.symptom_name,  
                "severity": s.severity,
                "frequency": s.frequency,
                "notes": s.notes,
                "created_at": s.created_at,
            })

        return Response({
            "patient_name": target_patient.first_name,
            "medicines": list(medicines),
            "symptoms": symptoms_data 
        }, status=status.HTTP_200_OK)

    except User.DoesNotExist:
        return Response({"error": "Patient not found"}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        print(f"❌ SERVER ERROR: {str(e)}")
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    # ... existing imports ...

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
        # Link the report to the logged-in user automatically
        serializer.save(user=self.request.user)
        serializer.save(user=self.request.user)



        # --- Doctor Views ---

class PatientListView(generics.ListAPIView):
    """
    API View to list all patients. 
    Used in the Doctor Dashboard to search and view patients.
    """
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated] # Ideally, restrict this to Doctors only in the future
    serializer_class = UserSerializer

    def get_queryset(self):
        # 1. Base Query: Get all users with role 'patient'
        queryset = User.objects.filter(role='patient')

        # 2. Search Logic: Filter by username, email, or first name if 'search' param exists
        search_query = self.request.query_params.get('search', None)
        if search_query:
            queryset = queryset.filter(
                Q(username__icontains=search_query) | 
                Q(email__icontains=search_query) |
                Q(first_name__icontains=search_query)
            )

        return queryset
    
# Load once when server starts
MODEL = joblib.load('api/ml_asssets/best_ra_xgb_model.joblib')
FEATURES = joblib.load('api/ml_asssets/gene_features.joblib')

class GeneUploadView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def post(self, request):
        file = request.FILES.get('file')

        if not file:
            return Response(
                {"error": "No file uploaded"},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            # 1. Preprocessing (Matches training pipeline)
            text_file = TextIOWrapper(file.file, encoding='utf-8')

            df = pd.read_csv(
                text_file,
                sep=',',          # explicit separator (IMPORTANT)
            )
            df=df.apply(pd.to_numeric, errors='coerce')

            df=df.fillna(0)
            df = df.reindex(columns=FEATURES, fill_value=0)            
            # expected_genes = joblib.load("ml_asssets/gene_features.joblib")
            expected_count = 2000
            current_count = df.shape[1]
            
            if current_count < expected_count:
                missing_cols = expected_count - current_count
                # Create a DataFrame of zeros with generic names
                extra_data = np.zeros((df.shape[0], missing_cols))
                extra_df = pd.DataFrame(extra_data, index=df.index)
                # Combine them
                df = pd.concat([df, extra_df], axis=1)
            df_log = np.log2(df + 1)

        except Exception as e:
            return Response(
                {"error": f"Gene processing failed: {str(e)}"},
                status=400
            )
        
        # 2. Prediction
        X = df_log.to_numpy()
        probability = MODEL.predict_proba(X)[0][1]
        print(f"Test Probability with max values: {probability}")
        # Inside post method, after np.log2 transformation:
        print(f"--- PREDICTION DEBUG ---")
        print(f"File: {file.name}")
        print(f"Mean expression value: {X.mean()}")
        print(f"Max expression value: {X.max()}")
        print(f"Number of non-zero features: {np.count_nonzero(X)}")


        risk_score = round(float(probability) * 100, 2)

        # 3. Save to DB (SAFE now because user is authenticated)
        report = GenePredictionReport.objects.create(
            patient=request.user,
            risk_percentage=risk_score,
            result_label="High Risk" if risk_score > 50 else "Low Risk",
            file_name=file.name
        )
        if list(df_log.columns) != list(FEATURES):
            return Response(
                {"error": "Uploaded gene expression file does not match model features"},
                status=400
            )
        return Response(
            {
                "percentage": risk_score,
                "label": report.result_label,
                "report_id": report.id
            },
            status=status.HTTP_200_OK
        )
