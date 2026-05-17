from django.contrib.auth.models import AbstractUser
from django.contrib.auth import get_user_model
from django.contrib.auth.models import User
from django.conf import settings
from django.db import models
import joblib
import shap

class User(AbstractUser):
    ROLE_CHOICES = (
        ('patient', 'Patient'),
        ('doctor', 'Doctor'),
        ('admin', 'Admin'),
    )

    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='patient')

    # Additional fields for patient information
    age = models.IntegerField(null=True, blank=True)  # Age of the patient
    weight = models.FloatField(null=True, blank=True)  # Weight in kg
    height = models.FloatField(null=True, blank=True)  # Height in cm
    gender = models.CharField(max_length=10, null=True, blank=True)  # Gender (optional)
    current_gene_file = models.ForeignKey(
        "FileUpload",
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="active_for_user"
    )
   
    def __str__(self):
        return f"{self.username} ({self.role})"
    
    # FileUpload model to store files associated with the user
class FileUpload(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)  # Link file to a user (patient)
    file = models.FileField(upload_to='uploads/')  # File upload path
    uploaded_at = models.DateTimeField(auto_now_add=True)  # Timestamp when file is uploaded

    def __str__(self):
        return f"File uploaded by {self.user.username} at {self.uploaded_at}"

User= get_user_model()
class Medicine(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='medicines')
    name = models.CharField(max_length=100)
    added_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.name} for {self.user.username}"


class SymptomReport(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="symptoms")
    symptom_name = models.CharField(max_length=100)
    severity = models.IntegerField()  # 0 to 10 scale
    frequency = models.CharField(max_length=50) 
    notes = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username} - {self.symptom_name} ({self.severity}/10)"

    
class DoctorPatient(models.Model):
    # These match your screenshot columns
    doctor_username = models.CharField(max_length=150)
    patient_username = models.CharField(max_length=150)
    status = models.CharField(max_length=20, default='pending') # pending, confirmed, declined
    appointment_date = models.CharField(max_length=50, null=True, blank=True) # Text column

    def __str__(self):
        return f"{self.doctor_username} -> {self.patient_username} ({self.status})"
    

class TwinRun(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="twin_runs")
    selected_drugs = models.JSONField()   # list of drugs
    results = models.JSONField()          # simulation output
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"TwinRun {self.id} - {self.user.username}"


class DrugInteraction(models.Model):
    drug_1 = models.CharField(max_length=255, db_index=True)
    drug_2 = models.CharField(max_length=255, db_index=True)
    interaction_description = models.TextField()

    def __str__(self):
        return f"{self.drug_1} - {self.drug_2}"
    

class GeneExpressionFile(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    file = models.FileField(upload_to='gene_data/')
    uploaded_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.id} - {self.file.name}"



MODEL = joblib.load('api/ml_asssets/best_ra_xgb_model.joblib')
FEATURES = joblib.load('api/ml_asssets/gene_features.joblib')
EXPLAINER = shap.Explainer(MODEL)

class GenePredictionReport(models.Model):
    patient = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    risk_percentage = models.FloatField()
    result_label = models.CharField(max_length=50)
    file_name = models.CharField(max_length=255)
    created_at = models.DateTimeField(auto_now_add=True)
    precision = models.FloatField(null=True, blank=True)
    recall = models.FloatField(null=True, blank=True)
    f1_score = models.FloatField(null=True, blank=True)
    confidence_interval = models.CharField(max_length=100, null=True, blank=True)
    top_affecting_genes = models.JSONField(null=True, blank=True)
    input_features = models.JSONField(null=True, blank=True)
    


class MedicalTestResult(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='medical_test_results',
        null=True,
        blank=True
    )

    age = models.IntegerField()
    gender = models.CharField(max_length=10)

    esr = models.FloatField(null=True, blank=True)
    crp = models.FloatField(null=True, blank=True)
    rf = models.FloatField(null=True, blank=True)
    anti_ccp = models.FloatField(null=True, blank=True)
    c3 = models.FloatField(null=True, blank=True)
    c4 = models.FloatField(null=True, blank=True)

    ana = models.BooleanField(default=False)
    anti_sm = models.BooleanField(default=False)
    anti_ro = models.BooleanField(default=False)
    hla_b27 = models.BooleanField(default=False)
    anti_la = models.BooleanField(default=False)
    anti_dsdna = models.BooleanField(default=False)

    disease_prediction = models.CharField(max_length=100)
    confidence = models.FloatField()
    xai_explanation = models.TextField()

    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user} - {self.disease_prediction} ({self.created_at:%Y-%m-%d %H:%M})"


class TwinSimulationReport(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    drug1 = models.CharField(max_length=255)
    drug2 = models.CharField(max_length=255, blank=True, null=True)
    file_name = models.CharField(max_length=255)

    best_drug = models.CharField(max_length=255)
    risk_reduction = models.FloatField(default=0)

    full_report = models.JSONField()

    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username} - {self.best_drug}"