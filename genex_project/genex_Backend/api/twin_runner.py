import os
import pickle
import numpy as np
import pandas as pd
import torch

from api.digital_twin import (
    DeepDenoisingAE,
    DigitalTwin,
    PipelineConfig,
    PATHWAYS,
)


BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ARTIFACT_DIR = os.path.join(BASE_DIR, "ml_api", "artifacts")


def load_pickle(file_name):
    path = os.path.join(ARTIFACT_DIR, file_name)

    if not os.path.exists(path):
        raise FileNotFoundError(f"Missing artifact: {path}")

    with open(path, "rb") as f:
        return pickle.load(f)


def load_twin_artifacts():
    gene_cols = load_pickle("twin_gene_cols.pkl")
    twin_scaler = load_pickle("twin_scaler.pkl")
    drug_to_targets = load_pickle("drug_to_targets.pkl")

    model_path = os.path.join(ARTIFACT_DIR, "twin_model.pth")
    healthy_tensor_path = os.path.join(ARTIFACT_DIR, "healthy_tensor.pt")

    if not os.path.exists(model_path):
        raise FileNotFoundError(f"Missing artifact: {model_path}")

    if not os.path.exists(healthy_tensor_path):
        raise FileNotFoundError(f"Missing artifact: {healthy_tensor_path}")

    healthy_tensor = torch.load(healthy_tensor_path, map_location="cpu")

    model = DeepDenoisingAE(
        input_dim=len(gene_cols),
        latent_dim=64
    )

    state = torch.load(model_path, map_location="cpu")
    model.load_state_dict(state)
    model.eval()

    return {
        "gene_cols": gene_cols,
        "twin_scaler": twin_scaler,
        "drug_to_targets": drug_to_targets,
        "healthy_tensor": healthy_tensor,
        "model": model,
    }


def load_patient_gene_file(file_path):
    try:
        df = pd.read_csv(file_path, sep="\t")
    except Exception:
        df = pd.read_csv(file_path)

    df.columns = [str(c).strip() for c in df.columns]

    gene_col = None
    for col in ["GeneSymbol", "Hugo_Symbol", "gene", "GENE", "symbol"]:
        if col in df.columns:
            gene_col = col
            break

    if gene_col is None:
        raise ValueError("Could not find gene symbol column in patient gene file.")

    expr_cols = [c for c in df.columns if c != gene_col]

    if not expr_cols:
        raise ValueError("No expression columns found in patient gene file.")

    df[gene_col] = df[gene_col].astype(str).str.strip().str.upper()
    df = df.drop_duplicates(subset=[gene_col])

    mat = df.set_index(gene_col)[expr_cols].apply(pd.to_numeric, errors="coerce")

    first_sample = mat.columns[0]
    patient_vec = mat[first_sample]

    return patient_vec


def build_patient_tensor(patient_vec, gene_cols, twin_scaler):
    patient_vec = patient_vec.copy()
    patient_vec.index = patient_vec.index.astype(str).str.upper()

    aligned = pd.Series({
        gene: pd.to_numeric(patient_vec.get(gene, np.nan), errors="coerce")
        for gene in gene_cols
    })

    aligned = aligned.fillna(0)

    scaled = twin_scaler.transform(
        pd.DataFrame([aligned.values], columns=gene_cols)
    )

    return torch.tensor(scaled, dtype=torch.float32)


def clean_for_json(value):
    if isinstance(value, pd.DataFrame):
        return value.replace({np.nan: None}).to_dict(orient="records")

    if isinstance(value, pd.Series):
        return value.replace({np.nan: None}).to_dict()

    if isinstance(value, dict):
        return {str(k): clean_for_json(v) for k, v in value.items()}

    if isinstance(value, list):
        return [clean_for_json(v) for v in value]

    if isinstance(value, tuple):
        return [clean_for_json(v) for v in value]

    if isinstance(value, np.integer):
        return int(value)

    if isinstance(value, np.floating):
        if np.isnan(value):
            return None
        return float(value)

    return value


def run_twin_runtime_for_user(user, drugs):
    if not getattr(user, "current_gene_file", None):
        raise ValueError("No active gene expression file found for this user.")

    artifacts = load_twin_artifacts()

    gene_cols = artifacts["gene_cols"]
    twin_scaler = artifacts["twin_scaler"]
    drug_to_targets = artifacts["drug_to_targets"]
    healthy_tensor = artifacts["healthy_tensor"]
    model = artifacts["model"]

    patient_file_path = user.current_gene_file.file.path
    patient_vec = load_patient_gene_file(patient_file_path)

    patient_tensor = build_patient_tensor(
        patient_vec=patient_vec,
        gene_cols=gene_cols,
        twin_scaler=twin_scaler,
    )

    config = PipelineConfig()

    twin = DigitalTwin(
        gene_cols=gene_cols,
        healthy_tensor=healthy_tensor,
        drug_to_targets=drug_to_targets,
        pathways=PATHWAYS,
        config=config,
    )

    baseline_risk = float(twin.calculate_risk(model, patient_tensor).item())

    single_results = []

    for drug in drugs:
        targets = twin._resolve_targets(drug)
        valid_targets = [g for g in targets if g in twin.idx]

        if not valid_targets:
            single_results.append({
                "drug_name": drug,
                "status": "no valid targets found",
                "valid_targets": [],
            })
            continue

        after = twin.simulate_single(
            patient=patient_tensor,
            valid_targets=valid_targets,
            alpha=config.sim_base_alpha,
        )

        after_risk = float(twin.calculate_risk(model, after).item())

        risk_reduction_pct = (
            ((baseline_risk - after_risk) / baseline_risk) * 100
            if baseline_risk != 0 else 0
        )

        single_results.append({
            "drug_name": drug,
            "baseline_risk": baseline_risk,
            "after_risk": after_risk,
            "risk_reduction_pct": risk_reduction_pct,
            "valid_targets": valid_targets,
            "pathway_hits": twin.pathway_hits(valid_targets),
            "gene_changes": clean_for_json([
                twin.gene_change(g, patient_tensor, after)
                for g in valid_targets[:10]
            ]),
        })

    pair_results = []

    for i in range(len(drugs)):
        for j in range(i + 1, len(drugs)):
            drug_a = drugs[i]
            drug_b = drugs[j]

            targets_a = [g for g in twin._resolve_targets(drug_a) if g in twin.idx]
            targets_b = [g for g in twin._resolve_targets(drug_b) if g in twin.idx]

            if not targets_a and not targets_b:
                continue

            after = twin.simulate_pair(
                patient=patient_tensor,
                valid_targets_a=targets_a,
                valid_targets_b=targets_b,
                alpha_a=config.sim_base_alpha,
                alpha_b=config.sim_base_alpha,
            )

            after_risk = float(twin.calculate_risk(model, after).item())

            risk_reduction_pct = (
                ((baseline_risk - after_risk) / baseline_risk) * 100
                if baseline_risk != 0 else 0
            )

            combined_targets = sorted(set(targets_a + targets_b))

            pair_results.append({
                "drug_pair": [drug_a, drug_b],
                "baseline_risk": baseline_risk,
                "after_risk": after_risk,
                "risk_reduction_pct": risk_reduction_pct,
                "valid_targets": combined_targets,
                "pathway_hits": twin.pathway_hits(combined_targets),
                "gene_changes": clean_for_json([
                    twin.gene_change(g, patient_tensor, after)
                    for g in combined_targets[:10]
                ]),
            })

    all_options = []

    for item in single_results:
        if "risk_reduction_pct" in item:
            all_options.append({
                "type": "single",
                "drug": item["drug_name"],
                "risk_reduction_pct": item["risk_reduction_pct"],
            })

    for item in pair_results:
        all_options.append({
            "type": "combination",
            "drug_pair": item["drug_pair"],
            "risk_reduction_pct": item["risk_reduction_pct"],
        })

    best_recommendation = (
        max(all_options, key=lambda x: x["risk_reduction_pct"])
        if all_options else None
    )

    return clean_for_json({
        "input_drugs": drugs,
        "baseline_risk": baseline_risk,
        "single_results": single_results,
        "pair_results": pair_results,
        "best_recommendation": best_recommendation,
    })

def minmax(series):
    s = pd.Series(series).astype(float)
    if s.max() == s.min():
        return s * 0
    return (s - s.min()) / (s.max() - s.min())


class FusionConfig:
    w_rank = 0.35
    w_twin = 0.35
    w_path = 0.20
    w_conf = 0.10
    w_pair_bonus = 0.10
    

def fuse_results(single_results, pair_results, df_rank):
    """
    df_rank MUST come from your ranking model (IC50 / ML).
    """

    rank_map = df_rank.copy()
    rank_map["drug_name"] = rank_map["drug_name"].str.lower()

    rank_map["rank_score"] = minmax(rank_map["final_score"])
    rank_map["conf_score"] = minmax(rank_map["score_conf"])

    # -------------------------
    # SINGLE DRUGS
    # -------------------------
    single_df = pd.DataFrame(single_results)

    if not single_df.empty:
        single_df["drug_name"] = single_df["drug_name"].str.lower()
        single_df["twin_score"] = minmax(single_df["risk_reduction_pct"])
    else:
        single_df = pd.DataFrame(columns=["drug_name", "twin_score"])

    # -------------------------
    # PAIRS
    # -------------------------
    pair_df = pd.DataFrame(pair_results)

    pair_expanded = []
    if not pair_df.empty:
        pair_df["pair_score"] = minmax(pair_df["risk_reduction_pct"])

        for _, r in pair_df.iterrows():
            a, b = r["drug_pair"]

            pair_expanded.append({"drug_name": a.lower(), "pair_bonus": r["pair_score"]})
            pair_expanded.append({"drug_name": b.lower(), "pair_bonus": r["pair_score"]})

    pair_df = pd.DataFrame(pair_expanded)

    # -------------------------
    # MERGE EVERYTHING
    # -------------------------
    merged = rank_map.merge(single_df, on="drug_name", how="left")
    merged = merged.merge(pair_df, on="drug_name", how="left")

    merged["twin_score"] = merged["twin_score"].fillna(0)
    merged["pair_bonus"] = merged["pair_bonus"].fillna(0)

    cfg = FusionConfig()

    merged["fusion_score"] = (
        cfg.w_rank * merged["rank_score"] +
        cfg.w_twin * merged["twin_score"] +
        cfg.w_path * merged["pair_bonus"] +
        cfg.w_conf * merged["conf_score"]
    )

    return merged.sort_values("fusion_score", ascending=False)
