from django.http import JsonResponse
from rest_framework import status, views, viewsets, permissions
from rest_framework.response import Response
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.authentication import JWTAuthentication

from .models import User, Medicine, SymptomReport
from .serializers import UserSerializer, MedicineSerializer, SymptomReportSerializer


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
    return str(refresh.access_token)


# --- API Root ---
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

    token = get_tokens_for_user(user)
    return Response({
        "token": token,
        "user": UserSerializer(user).data
    }, status=status.HTTP_201_CREATED)


@api_view(['POST'])
@permission_classes([AllowAny])
def signin(request):
    """Authenticates user and returns JWT token."""
    email = request.data.get('email')
    password = request.data.get('password')

    if not email or not password:
        return Response(
            {"error": "Email and password are required"},
            status=status.HTTP_400_BAD_REQUEST
        )

    try:
        user = User.objects.get(username=email)
    except User.DoesNotExist:
        return Response({"error": "Invalid credentials"}, status=status.HTTP_401_UNAUTHORIZED)

    if not user.check_password(password):
        return Response({"error": "Invalid credentials"}, status=status.HTTP_401_UNAUTHORIZED)

    token = get_tokens_for_user(user)
    return Response({
        "token": token,
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
    """
    Handles List, Create, and Delete for Patient Medicines.
    Uses JWT to ensure users only access their own data.
    """
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]
    serializer_class = MedicineSerializer

    def get_queryset(self):
        # Automatically filters so patients only see their OWN medicine history
        return Medicine.objects.filter(user=self.request.user).order_by('-added_at')

    def perform_create(self, serializer):
        # Automatically links the new medicine to the logged-in user
        serializer.save(user=self.request.user)


class SymptomViewSet(viewsets.ModelViewSet):
    """
    Handles List and Create for Patient Symptoms.
    """
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]
    serializer_class = SymptomReportSerializer

    def get_queryset(self):
        # Filter reports so patients only see their OWN logs
        return SymptomReport.objects.filter(user=self.request.user).order_by('-created_at')

    def perform_create(self, serializer):
        # Link the report to the logged-in user automatically
<<<<<<< Updated upstream
        serializer.save(user=self.request.user)
=======
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
>>>>>>> Stashed changes
