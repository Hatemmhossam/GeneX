import torch
import joblib
import numpy as np
import requests
import torch.nn as nn
from .digital_twin import DeepDenoisingAE,DigitalTwin

# -------------------------
# CONFIG (temporary safe fix)
# -------------------------
class DummyConfig:
    sim_pair_extra_alpha = 0.1
    
class MLService:

    def __init__(self):
        self.loaded = False

    def load_artifacts(self):
        if self.loaded:
            return

        path = "ml_api/artifacts"
        self.gene_cols = joblib.load(f"{path}/twin_gene_cols.pkl")
        self.scaler = joblib.load(f"{path}/twin_scaler.pkl")
        # self.S = joblib.load(f"{path}/genes.pkl")
        self.drug_map = joblib.load(f"{path}/drug_to_targets.pkl")
        # self.pathways = joblib.load(f"{path}/pathways.pkl")

        self.model = DeepDenoisingAE(
            input_dim=len(self.gene_cols),
            latent_dim=64
        )

        state = torch.load(
            f"{path}/twin_model.pth",
            map_location="cpu"
        )

        self.model.load_state_dict(state)
        self.model.eval()

        healthy_tensor = torch.zeros((1, len(self.gene_cols)))
        self.twin = DigitalTwin(
            gene_cols=self.gene_cols,
            healthy_tensor=healthy_tensor,
            drug_to_targets=self.drug_map,
            # pathways=self.pathways,
            config=DummyConfig()
        )

        self.loaded = True

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

        return torch.tensor(vec, dtype=torch.float32)
    

    def fetch_from_dgidb(self, drug_name):
        try:
            url = "https://dgidb.org/api/graphql"

            query = """
            query GetDrugInteractions($drugName: String!) {
            drugs(names: [$drugName]) {
                nodes {
                interactions {
                    gene {
                    name
                    }
                }
                }
            }
            }
            """

            variables = {
                "drugName": drug_name.upper().strip()
            }

            response = requests.post(
                url,
                json={
                    "query": query,
                    "variables": variables
                },
                timeout=15
            )

            print("STATUS:", response.status_code)
            print("TEXT:", response.text[:500])

            if response.status_code != 200:
                return []

            data = response.json()

            nodes = data.get("data", {}).get("drugs", {}).get("nodes", [])

            if not nodes:
                return []

            interactions = nodes[0].get("interactions", [])

            genes = []
            for interaction in interactions:
                gene = interaction.get("gene", {})
                gene_name = gene.get("name")
                if gene_name:
                    genes.append(gene_name.upper())

            return list(set(genes))

        except Exception as e:
            print("DGIdb GraphQL failed:", e)
            return []
        
   # -------------------------
    # SINGLE DRUG SCORE
    # -------------------------
   
    def evaluate_single(self, drug_name, patient_df):

        self.load_artifacts()

        patient_tensor = self.build_patient_vector(patient_df)

        # baseline risk
        base_risk = self.twin.calculate_risk(self.model, patient_tensor)

        raw_genes = self.fetch_from_dgidb(drug_name)

        genes = [g for g in raw_genes if g in self.gene_cols]

    #  USE DIGITAL TWIN (NOT SERVICE LOGIC)
        after = self.twin.simulate_single(
            # model=self.model,
            patient=patient_tensor,
            valid_targets=genes,
            alpha=0.5
        )

        new_risk = self.twin.calculate_risk(self.model, after)

        base_risk_val = float(base_risk.item())
        new_risk_val = float(new_risk.item())

        reduction = (
            ((base_risk_val - new_risk_val) / base_risk_val) * 100
            if base_risk_val != 0 else 0
        )

        return {
            "drug": drug_name,
            "baseline_risk": base_risk_val,
            "after_risk": new_risk_val,
            "risk_reduction": float(reduction)
        }
    # -------------------------
    # COMBO SCORE
    # -------------------------
    
    def evaluate_combo(self, drug1, drug2, patient_df):
        self.load_artifacts()

        patient_tensor = self.build_patient_vector(patient_df)
        base_risk = self.twin.calculate_risk(self.model, patient_tensor)

        raw_genes_a = self.fetch_from_dgidb(drug1)
        genes_a = [g for g in raw_genes_a if g in self.gene_cols]

        raw_genes_b = self.fetch_from_dgidb(drug2)

        genes_b = [g for g in raw_genes_b if g in self.gene_cols]

        # 🔥 USE DIGITAL TWIN FOR PAIR SIMULATION
        after = self.twin.simulate_pair(
            # model=self.model,
            patient=patient_tensor,
            valid_targets_a=genes_a,
            valid_targets_b=genes_b,
            alpha_a=0.5,
            alpha_b=0.5
        )

        new_risk = self.twin.calculate_risk(self.model, after)

        base_risk_val = float(base_risk.item())
        new_risk_val = float(new_risk.item())

        reduction = (
            ((base_risk_val - new_risk_val) / base_risk_val) * 100
            if base_risk_val != 0 else 0
        )

        return {
            "drug_pair": [drug1, drug2],
            "baseline_risk": base_risk_val,
            "after_risk": new_risk_val,
            "risk_reduction": float(reduction)
        }
    # -------------------------
    # MAIN FUNCTION 
    # # -------------------------
    def evaluate(self, drug1=None, drug2=None, patient_df=None):
        try:

            self.load_artifacts()
        
            results = []

            if drug1:
                results.append(self.evaluate_single(drug1, patient_df))

            if drug2:
                results.append(self.evaluate_single(drug2, patient_df))

            combo = None
            if drug1 and drug2:
                combo = self.evaluate_combo(drug1, drug2, patient_df)
                results.append(combo)

            valid_results = [
                r for r in results
                if r and r.get("baseline_risk",0) is not None
            ]
            positive_results = [
                r for r in valid_results
                if r.get("risk_reduction", 0) > 0
            ]
            best = max(
                positive_results,
                key=lambda x: x.get("risk_reduction", 0),
                default=None
            )
            if not best:
                return {
                    "all_results": results,
                    "message": "No safe drug found (all drugs worsen gene profile)"
                }
            return {
                "all_results": results,
                "best_recommendation": best,
            }
        
        except Exception as e:
            print("🔥 ERROR:", str(e))
            return {"error": str(e)}
    
   