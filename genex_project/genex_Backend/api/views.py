from django.http import JsonResponse
from django.db.models import Q 
from rest_framework import status, views, viewsets, permissions, generics 
from rest_framework.response import Response
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.authentication import JWTAuthentication

# ✅ UPDATED IMPORTS: Added DoctorPatient and new serializers
from .models import User, Medicine, SymptomReport, DoctorPatient
from .serializers import (
    UserSerializer, 
    MedicineSerializer, 
    SymptomReportSerializer, 
    PatientSerializer, 
    DoctorPatientSerializer
)

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
    username = request.data.get('username')
    password = request.data.get('password')

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
        serializer.save(user=self.request.user)


# --- Doctor / Patient Interaction Views ---

class PatientSearchView(generics.ListAPIView):
    """
    API View specifically for searching patients.
    """
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated] 
    serializer_class = PatientSerializer

    def get_queryset(self):
        # 1. Start with all users
        queryset = User.objects.all()
        
        # 2. Filter ONLY for patients
        queryset = queryset.filter(role='patient')

        # 3. Filter by the search query from the URL (e.g. ?query=john)
        search_query = self.request.query_params.get('query', None)
        if search_query:
            queryset = queryset.filter(username__icontains=search_query)
            
        return queryset

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def send_patient_request(request):
    print("--- NEW REQUEST RECEIVED ---") # Debug 1
    doctor_username = request.user.username
    patient_username = request.data.get('patient_username')

    print(f"Doctor: {doctor_username}, Patient: {patient_username}") # Debug 2

    if not patient_username:
        print("Error: No patient username provided")
        return Response({'error': 'Patient username is required'}, status=status.HTTP_400_BAD_REQUEST)

    # Check if request already exists
    existing = DoctorPatient.objects.filter(
        doctor_username=doctor_username, 
        patient_username=patient_username
    ).exists()

    if existing:
        print("Error: Request already exists in database")
        return Response({'message': 'Request already exists'}, status=status.HTTP_400_BAD_REQUEST)

    data = {
        'doctor_username': doctor_username,
        'patient_username': patient_username,
        'status': 'pending',
        'appointment_date': 'TBD'
    }
    
    serializer = DoctorPatientSerializer(data=data)
    if serializer.is_valid():
        serializer.save()
        print("SUCCESS: Data saved to database!") # Debug 3
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    
    print(f"VALIDATION ERROR: {serializer.errors}") # Debug 4
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
# (Optional: Kept for backward compatibility if you used it before)
class PatientListView(generics.ListAPIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]
    serializer_class = UserSerializer

    def get_queryset(self):
        queryset = User.objects.filter(role='patient')
        search_query = self.request.query_params.get('search', None)
        if search_query:
            queryset = queryset.filter(
                Q(username__icontains=search_query) | 
                Q(email__icontains=search_query) |
                Q(first_name__icontains=search_query)
            )
        return queryset