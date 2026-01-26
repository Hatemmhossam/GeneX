# api/serializers.py
from rest_framework import serializers
from .models import User
from .models import Medicine

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = [
            'id',
            'first_name',
            'email',
            'role',
            'age',
            'gender',
            'weight',
            'height',
        ]
        read_only_fields = ['id', 'email', 'role', 'first_name']


class MedicineSerializer(serializers.ModelSerializer):
    class Meta:
        model = Medicine
        fields = ['id', 'name', 'added_at']
        read_only_fields = ['id', 'added_at']
