from api.models import DoctorPatient
from django.contrib.auth import get_user_model

User = get_user_model()


def can_doctor_and_patient_chat(doctor, patient):
    return DoctorPatient.objects.filter(
        doctor_username=doctor.username,
        patient_username=patient.username,
        status='accepted'
    ).exists()