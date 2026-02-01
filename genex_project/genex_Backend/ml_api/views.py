import json
import os
import joblib
import pandas as pd
import numpy as np
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.conf import settings

# --- 1. Load Model & Preprocessing Artifacts ---
# Use os.path to find the file relative to this script
CURRENT_DIR = os.path.dirname(__file__)
MODEL_PATH = os.path.join(CURRENT_DIR, 'calibrated_model.joblib')

try:
    # Load the pipeline/model
    model = joblib.load(MODEL_PATH)
    print("Model loaded successfully!")
except Exception as e:
    print(f"Error loading model: {e}")
    model = None

# --- 2. Define Helper Functions (XAI Placeholder) ---
def simple_rule_based_explanation(row, prediction, confidence):
    """
    Since the specific XAI class was not found, this function generates 
    a logic-based explanation using medical domain knowledge for Rheumatic diseases.
    """
    reasons = []
    
    # Check for strong signals based on your dataset columns
    if row['Anti-CCP'][0] > 20: 
        reasons.append("High Anti-CCP levels (specific to Rheumatoid Arthritis)")
    if row['RF'][0] > 20:
        reasons.append("Elevated Rheumatoid Factor")
    if row['HLA-B27'][0] == "Positive":
        reasons.append("Positive HLA-B27 marker")
    if row['ANA'][0] == "Positive":
        reasons.append("Positive Antinuclear Antibody (ANA)")
    if row['Anti-dsDNA'][0] == "Positive":
        reasons.append("Positive Anti-dsDNA (suggestive of Lupus)")

    # Construct the text
    if not reasons:
        explanation = f"The model predicts {prediction} with {confidence*100:.1f}% confidence based on the overall symptom pattern."
    else:
        explanation = f"The model predicts {prediction} ({confidence*100:.1f}% confidence).\n\nKey contributing factors:\n- " + "\n- ".join(reasons)
    
    return explanation

@csrf_exempt
def predict_xai(request):
    if request.method == 'POST':
        try:
            # --- 3. Parse JSON from Flutter ---
            data = json.loads(request.body)
            
            # --- 4. Prepare DataFrame (Input Logic) ---
            # NOTE: We map Flutter's booleans to "Positive"/"Negative" 
            # because your notebook uses these string values.
            input_dict = {
                "Age": [data.get('Age', 0)],
                "Gender": [data.get('Gender', 'Female')],
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

            # Check if model loaded correctly
            if model is None:
                return JsonResponse({'error': 'Model file not found or failed to load.'}, status=500)

            # --- 5. Make Prediction ---
            # We use [0] because predict returns an array, we want the first item
            prediction = model.predict(df_input)[0]
            
            # Get probability/confidence
            if hasattr(model, "predict_proba"):
                probabilities = model.predict_proba(df_input)[0].tolist()
                confidence = max(probabilities)
            else:
                confidence = 1.0 # Fallback if model doesn't support probabilities

            # --- 6. Generate XAI Explanation ---
            # If you have your own class, uncomment the lines below and import it.
            # explainer = DiseaseXAILayer(model, df_input)
            # xai_explanation = explainer.explain()
            
            # For now, use the rule-based helper defined above:
            xai_explanation = simple_rule_based_explanation(input_dict, prediction, confidence)

            return JsonResponse({
                'disease_prediction': str(prediction),
                'confidence': confidence,
                'xai_explanation': xai_explanation
            })

        except Exception as e:
            # Return detailed error for debugging
            import traceback
            traceback.print_exc()
            return JsonResponse({'error': str(e)}, status=400)
    
    return JsonResponse({'error': 'POST method required'}, status=405)