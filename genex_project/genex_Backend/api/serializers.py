# api/serializers.py
from rest_framework import serializers
from .models import User
from .models import Medicine
from .models import SymptomReport 
from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import DoctorPatient
from .models import GenePredictionReport
from .models import MedicalTestResult

User = get_user_model()
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

# ✅ ADD THIS CLASS
class PatientSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        # These are the fields the Flutter app will receive
        fields = [ 'id',
            'username',  
            'first_name',
            'email',
            'role',
            'age',
            'gender',
            'weight',
            'height',]
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

class DoctorPatientSerializer(serializers.ModelSerializer):
    class Meta:
        model = DoctorPatient
        fields = ['id', 'doctor_username', 'patient_username', 'status', 'appointment_date']


class GeneReportSerializer(serializers.ModelSerializer):
    percentage = serializers.FloatField(source='risk_percentage', read_only=True)
    label = serializers.CharField(source='result_label', read_only=True)
    date = serializers.DateTimeField(source='created_at', read_only=True)
    filename = serializers.CharField(source='file_name', read_only=True)

    top_affecting_genes = serializers.SerializerMethodField()
    doctor_permission = serializers.SerializerMethodField()
    permission_status = serializers.SerializerMethodField()

    class Meta:
        model = GenePredictionReport
        fields = [
            'id',
            'percentage',
            'label',
            'date',
            'filename',
            'precision',
            'recall',
            'f1_score',
            'confidence_interval',
            'top_affecting_genes',
            'doctor_permission',
            'permission_status',
        ]

    def get_top_affecting_genes(self, obj):
        try:
            return obj.top_affecting_genes or {}
        except Exception:
            return {}

    def get_doctor_permission(self, obj):
        try:
            return obj.permission_requests.filter(status='approved').exists()
        except Exception:
            return False

    def get_permission_status(self, obj):
        try:
            request = obj.permission_requests.order_by('-id').first()

            if request:
                return request.status

            return 'not_requested'
        except Exception:
            return 'not_requested'
        
class MedicalTestResultSerializer(serializers.ModelSerializer):
    class Meta:
        model = MedicalTestResult
        fields = [
            'id',
            'age',
            'gender',
            'esr',
            'crp',
            'rf',
            'anti_ccp',
            'c3',
            'c4',
            'ana',
            'anti_sm',
            'anti_ro',
            'hla_b27',
            'anti_la',
            'anti_dsdna',
            'disease_prediction',
            'confidence',
            'xai_explanation',
            'created_at',
        ]