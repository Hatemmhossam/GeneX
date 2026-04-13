from django.http import JsonResponse
from rest_framework import status, views, viewsets, permissions
from rest_framework.response import Response
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.authentication import JWTAuthentication
<<<<<<< Updated upstream

from .models import User, Medicine, SymptomReport
from .serializers import UserSerializer, MedicineSerializer, SymptomReportSerializer
=======
from django.db import connection
from rest_framework.parsers import MultiPartParser, FormParser
from .services import run_twin_simulation
# ✅ IMPORTS: Ensure all your models and serializers are here
from .models import User, Medicine, SymptomReport, DoctorPatient, FileUpload, TwinRun
from .serializers import (
    UserSerializer, 
    MedicineSerializer, 
    SymptomReportSerializer, 
    PatientSerializer
)
print("\n\n🔥 RELOADING VIEWS.PY - IF YOU SEE THIS, THE NEW CODE IS ACTIVE! 🔥\n\n")
>>>>>>> Stashed changes

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
        serializer.save(user=self.request.user)