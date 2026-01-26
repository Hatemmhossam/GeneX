# views.py
from .models import User, Medicine
from rest_framework.response import Response
from rest_framework.decorators import api_view, permission_classes
from rest_framework_simplejwt.tokens import RefreshToken
import json
from rest_framework.views import APIView
from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework.permissions import IsAuthenticated
from rest_framework import status, views
from .serializers import UserSerializer, MedicineSerializer
from django.http import JsonResponse

from rest_framework import viewsets, permissions 
from .models import Medicine

from rest_framework.permissions import AllowAny


# Helper function to generate JWT token
def get_tokens_for_user(user):
    refresh = RefreshToken.for_user(user)
    return str(refresh.access_token)

@api_view(['POST'])
@permission_classes([AllowAny])
def signup(request):
    data = request.data

    email = data.get('email')
    password = data.get('password')
    name = data.get('name')
    role = data.get('role', 'patient')

    age = data.get('age')
    gender = data.get('gender')
    height = data.get('height')
    weight = data.get('weight')

    if not email or not password or not name:
        return Response(
            {"error": "Email, password, and name are required"},
            status=status.HTTP_400_BAD_REQUEST
        )

    if User.objects.filter(username=email).exists():
        return Response(
            {"error": "User already exists"},
            status=status.HTTP_400_BAD_REQUEST
        )

    user = User.objects.create_user(
        username=email,
        email=email,
        password=password,
        first_name=name,
        role=role,
        age=age,
        gender=gender,
        height=height,
        weight=weight,
    )

    token = get_tokens_for_user(user)

    return Response(
        {
            "token": token,
            "user": {
                "id": user.id,
                "name": user.first_name,
                "email": user.email,
                "role": user.role,
                "age": user.age,
                "gender": user.gender,
                "height": user.height,
                "weight": user.weight,
            },
        },
        status=status.HTTP_201_CREATED,
    )


@api_view(['POST'])
@permission_classes([AllowAny])
def signin(request):
    """
    Sign in existing user and return JWT token with user info
    """
    data = request.data
    email = data.get('email')
    password = data.get('password')

    if not email or not password:
        return Response({"error": "Email and password are required"},
                        status=status.HTTP_400_BAD_REQUEST)

    try:
        user = User.objects.get(username=email)
    except User.DoesNotExist:
        return Response({"error": "Invalid credentials"},
                        status=status.HTTP_401_UNAUTHORIZED)

    if not user.check_password(password):
        return Response({"error": "Invalid credentials"},
                        status=status.HTTP_401_UNAUTHORIZED)

    token = get_tokens_for_user(user)

    # You can get role from profile if you have a profile model

    return Response({
        "token": token,
        "user": {
            "id": user.id,
            "name": user.first_name,
            "email": user.email,
            "role": user.role 
        }
    })

class ProfileView(views.APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def get(self, request):
        # This single method handles the request
        serializer = UserSerializer(request.user)
        return Response(serializer.data, status=status.HTTP_200_OK)
    
    def patch(self, request):
        user = request.user
        serializer = UserSerializer(user, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)




def api_root(request):
    return JsonResponse({
        "message": "GENEX API is running"
    })



# START OF MEDICINE VIEWS

# class MedicineListCreateView(APIView):
#     authentication_classes = [JWTAuthentication]
#     permission_classes = [IsAuthenticated]

#     def get(self, request):
#         medicines = Medicine.objects.filter(user=request.user)
#         serializer = MedicineSerializer(medicines, many=True)
#         return Response(serializer.data)

#     def post(self, request):
#         serializer = MedicineSerializer(data=request.data)
#         if serializer.is_valid():
#             serializer.save(user=request.user)
#             return Response(serializer.data, status=status.HTTP_201_CREATED)
#         return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

# class MedicineDeleteView(APIView):
#     authentication_classes = [JWTAuthentication]
#     permission_classes = [IsAuthenticated]

#     def delete(self, request, pk):
#         try:
#             medicine = Medicine.objects.get(pk=pk, user=request.user)
#             medicine.delete()
#             return Response(status=status.HTTP_204_NO_CONTENT)
#         except Medicine.DoesNotExist:
#             return Response({"error": "Medicine not found"}, status=status.HTTP_404_NOT_FOUND)


class MedicineViewSet(viewsets.ModelViewSet):
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = MedicineSerializer

    def get_queryset(self):
        return Medicine.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)
