import torch
import joblib
import numpy as np
import pandas as pd


class MLService:

    def __init__(self):
        self.loaded = False

    # -------------------------
    # LOAD ARTIFACTS
    # -------------------------
    def load_artifacts(self):

        if self.loaded:
            return

        path = "ml_api/artifacts"

        self.model = torch.load(f"{path}/twin_model.pth", map_location="cpu")

        self.scaler = joblib.load(f"{path}/twin_scaler.pkl")
        self.gene_cols = joblib.load(f"{path}/twin_gene_cols.pkl")

        # 🔥 THIS IS YOUR DGIdb SOURCE (IMPORTANT)
        self.drug_map = joblib.load(f"{path}/drug_to_targets.pkl")

        self.loaded = True
        print("✔ Artifacts loaded")

    # -------------------------
    # PATIENT VECTOR BUILDER
    # -------------------------
    def build_patient_vector(self, df):

        vec = []

        for g in self.gene_cols:
            if g in df.columns:
                vec.append(df[g].values[0])
            else:
                vec.append(0)

        vec = np.array(vec).reshape(1, -1)
        vec = self.scaler.transform(vec)

        return vec

    # -------------------------
    # SINGLE DRUG SCORE
    # -------------------------
    def evaluate_single(self, drug_name, patient_df):

        drug_targets = self.drug_map.get(drug_name)

        if not drug_targets:
            return None

        hits = sum([1 for g in drug_targets if g in self.gene_cols])

        score = hits / (len(drug_targets) + 1)

        return {
            "drug": drug_name,
            "score": float(score),
            "hits": hits
        }

    # -------------------------
    # COMBO SCORE
    # -------------------------
    def evaluate_combo(self, drug1, drug2, patient_df):

        d1 = self.drug_map.get(drug1, [])
        d2 = self.drug_map.get(drug2, [])

        combined = set(d1 + d2)

        hits = sum([1 for g in combined if g in self.gene_cols])

        score = hits / (len(combined) + 1)

        return {
            "drug_pair": [drug1, drug2],
            "score": float(score),
            "hits": hits
        }

    # -------------------------
    # MAIN FUNCTION 
    # -------------------------
    def evaluate(self, drug1=None, drug2=None, patient_df=None):

        if not self.loaded:
            self.load_artifacts()

        results = []

        # always evaluate first drug
        if drug1:
            r1 = self.evaluate_single(drug1, patient_df)
            if r1:
                results.append(r1)

        # second drug
        if drug2:
            r2 = self.evaluate_single(drug2, patient_df)
            if r2:
                results.append(r2)

        # combo if 2 drugs exist
        combo = None
        if drug1 and drug2:
            combo = self.evaluate_combo(drug1, drug2, patient_df)
            results.append({
                "drug": f"{drug1}+{drug2}",
                "score": combo["score"],
                "hits": combo["hits"]
            })

        # -------------------------
        # FIND BEST
        # -------------------------
        best = max(results, key=lambda x: x["score"]) if results else None

        return {
            "all_results": results,
            "best_recommendation": best
        }