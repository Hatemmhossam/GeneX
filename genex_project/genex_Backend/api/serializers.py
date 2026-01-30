# api/serializers.py
from rest_framework import serializers
from .models import User
from .models import Medicine
from .models import SymptomReport 

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = [
            'id',
            'username',  
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

class SymptomReportSerializer(serializers.ModelSerializer):
    class Meta:
        model = SymptomReport
        fields = ['id', 'symptom_name', 'severity', 'frequency', 'notes', 'created_at']
        read_only_fields = ['id', 'created_at']