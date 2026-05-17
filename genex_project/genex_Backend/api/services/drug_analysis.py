# api/services/drug_analysis.py
import os
import pandas as pd

import os
import pandas as pd

def analyze_drug_with_file(drug: str, file_path: str):
    file_path = str(file_path).strip()

    if not os.path.exists(file_path):
        raise FileNotFoundError(f"File not found: {file_path}")

    if file_path.endswith(".txt"):
        df = pd.read_csv(file_path, sep="\t", encoding="utf-8-sig")
    elif file_path.endswith(".csv"):
        df = pd.read_csv(file_path, encoding="utf-8-sig")
    elif file_path.endswith(".xlsx"):
        df = pd.read_excel(file_path)
    else:
        raise ValueError("Unsupported file type: use csv, xlsx, or txt")

    df.columns = df.columns.str.strip().str.replace("\ufeff", "", regex=False)

    # -----------------------------
    # TEMP DEMO: use your actual model result structure
    # Replace this section with your real notebook/model inference
    # -----------------------------
    drug_key = drug.strip().lower()

    predicted_results = {
        "dovitinib": {
            "drug": "dovitinib",
            "combined_score": 0.8398,
            "rank_score": 0.7216,
            "ic50": 1.5226,
            "twin_reduction": 3.664,
            "best_model": "extra_trees",
            "marker_x": 170,
            "marker_y": 220,
        },
        "tozasertib": {
            "drug": "tozasertib",
            "combined_score": 0.8142,
            "rank_score": 0.7433,
            "ic50": 0.4922,
            "twin_reduction": 3.589,
            "best_model": "random_forest",
            "marker_x": 210,
            "marker_y": 220,
        },
    }

    if drug_key not in predicted_results:
        return {
            "drug": drug,
            "combined_score": None,
            "rank_score": None,
            "ic50": None,
            "twin_reduction": None,
            "best_model": "Unknown",
            "marker_x": 170,
            "marker_y": 220,
            "message": "Drug not found in ranking results."
        }

    return predicted_results[drug_key]