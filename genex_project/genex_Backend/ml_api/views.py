import os
import joblib
import pandas as pd
import numpy as np

from rest_framework.decorators import api_view, authentication_classes, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from rest_framework_simplejwt.authentication import JWTAuthentication

from api.models import MedicalTestResult

# --- 1. Load Model & Preprocessing Artifacts ---
CURRENT_DIR = os.path.dirname(__file__)
MODEL_PATH = os.path.join(CURRENT_DIR, 'calibrated_model.joblib')

try:
    model = joblib.load(MODEL_PATH)
    print("Model loaded successfully!")
except Exception as e:
    print(f"Error loading model: {e}")
    model = None


# --- 2. Define Helper Functions ---
def simple_rule_based_explanation(row, prediction, confidence):
    reasons = []

    anti_ccp = row['Anti-CCP'][0]
    rf = row['RF'][0]

    if pd.notna(anti_ccp) and anti_ccp > 20:
        reasons.append("High Anti-CCP levels (specific to Rheumatoid Arthritis)")
    if pd.notna(rf) and rf > 20:
        reasons.append("Elevated Rheumatoid Factor")
    if row['HLA-B27'][0] == "Positive":
        reasons.append("Positive HLA-B27 marker")
    if row['ANA'][0] == "Positive":
        reasons.append("Positive Antinuclear Antibody (ANA)")
    if row['Anti-dsDNA'][0] == "Positive":
        reasons.append("Positive Anti-dsDNA (suggestive of Lupus)")

    if not reasons:
        explanation = (
            f"The model predicts {prediction} with "
            f"{confidence * 100:.1f}% confidence based on the overall symptom pattern."
        )
    else:
        explanation = (
            f"The model predicts {prediction} ({confidence * 100:.1f}% confidence).\n\n"
            f"Key contributing factors:\n- " + "\n- ".join(reasons)
        )

    return explanation

@api_view(['POST'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def predict_xai(request): #save to database and call model

    try:
        data = request.data
        user = request.user

        # Take age and gender directly from logged-in user
        age = user.age
        gender = user.gender

        if age is None:
            return Response(
                {'error': 'Your profile is missing age. Please update it first.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        if not gender:
            return Response(
                {'error': 'Your profile is missing gender. Please update it first.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        input_dict = {
            "Age": [age],
            "Gender": [gender],
            "ESR": [data.get('ESR') if data.get('ESR') is not None else np.nan],
            "CRP": [data.get('CRP') if data.get('CRP') is not None else np.nan],
            "RF": [data.get('RF') if data.get('RF') is not None else np.nan],
            "Anti-CCP": [data.get('Anti_CCP') if data.get('Anti_CCP') is not None else np.nan],
            "HLA-B27": ["Positive" if data.get('HLA_B27') else "Negative"],
            "ANA": ["Positive" if data.get('ANA') else "Negative"],
            "Anti-Ro": ["Positive" if data.get('Anti_Ro') else "Negative"],
            "Anti-La": ["Positive" if data.get('Anti_La') else "Negative"],
            "Anti-dsDNA": ["Positive" if data.get('Anti_dsDNA') else "Negative"],
            "Anti-Sm": ["Positive" if data.get('Anti_Sm') else "Negative"],
            "C3": [data.get('C3') if data.get('C3') is not None else np.nan],
            "C4": [data.get('C4') if data.get('C4') is not None else np.nan],
        }

        df_input = pd.DataFrame(input_dict)

        if model is None:
            return Response(
                {'error': 'Model not loaded'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

        prediction = model.predict(df_input)[0]

        if hasattr(model, "predict_proba"):
            probabilities = model.predict_proba(df_input)[0].tolist()
            confidence = float(max(probabilities))
        else:
            confidence = 1.0

        xai_explanation = simple_rule_based_explanation(
            input_dict, prediction, confidence
        )

        saved_result = MedicalTestResult.objects.create(
            user=user,
            age=age,
            gender=gender,

            esr=data.get('ESR'),
            crp=data.get('CRP'),
            rf=data.get('RF'),
            anti_ccp=data.get('Anti_CCP'),
            c3=data.get('C3'),
            c4=data.get('C4'),

            ana=data.get('ANA', False),
            anti_sm=data.get('Anti_Sm', False),
            anti_ro=data.get('Anti_Ro', False),
            hla_b27=data.get('HLA_B27', False),
            anti_la=data.get('Anti_La', False),
            anti_dsdna=data.get('Anti_dsDNA', False),

            disease_prediction=str(prediction),
            confidence=confidence,
            xai_explanation=xai_explanation
        )

        return Response({
            'message': 'Prediction completed and saved successfully',
            'result_id': saved_result.id,
            'user_id': user.id,
            'disease_prediction': str(prediction),
            'confidence': confidence,
            'xai_explanation': xai_explanation,
            'age': age,
            'gender': gender,
        }, status=status.HTTP_200_OK)

    except Exception as e:
        import traceback
        traceback.print_exc()
        return Response(
            {'error': str(e)},
            status=status.HTTP_400_BAD_REQUEST
        )