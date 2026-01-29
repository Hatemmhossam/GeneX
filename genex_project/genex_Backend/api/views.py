from django.http import JsonResponse
from rest_framework import status, views, viewsets, permissions
from rest_framework.response import Response
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.authentication import JWTAuthentication

from .models import User, Medicine, SymptomReport
from .serializers import UserSerializer, MedicineSerializer, SymptomReportSerializer

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