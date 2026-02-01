from django.contrib.auth.models import AbstractUser
from django.contrib.auth import get_user_model
from django.conf import settings
from django.db import models

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
    
    
class GenePredictionReport(models.Model):
    patient = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    risk_percentage = models.FloatField()
    result_label = models.CharField(max_length=50) # e.g., "High Risk"
    created_at = models.DateTimeField(auto_now_add=True)
    file_name = models.CharField(max_length=255)

    def __str__(self):
        return f"{self.patient.email} - {self.risk_percentage}%"