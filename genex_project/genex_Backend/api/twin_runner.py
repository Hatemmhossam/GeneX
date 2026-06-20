import os
import pickle
import numpy as np
import pandas as pd
import torch
import joblib
import requests
import math

from .xai import run_xai_analysis

from api.digital_twin import (
    DeepDenoisingAE,
    DigitalTwin,
    PipelineConfig,
    PATHWAYS,
)


BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ARTIFACT_DIR = os.path.join(BASE_DIR, "ml_api", "artifacts")


def load_artifact(file_name):
    path = os.path.join(ARTIFACT_DIR, file_name)

    if not os.path.exists(path):
        raise FileNotFoundError(f"Missing artifact: {path}")

    return joblib.load(path)


def load_twin_artifacts():
    gene_cols = load_artifact("twin_gene_cols.pkl")
    twin_scaler = load_artifact("twin_scaler.pkl")
    drug_to_targets = load_artifact("drug_to_targets.pkl")

    model_path = os.path.join(ARTIFACT_DIR, "twin_model.pth")
    healthy_tensor_path = os.path.join(ARTIFACT_DIR, "healthy_tensor.pt")

    if not os.path.exists(model_path):
        raise FileNotFoundError(f"Missing artifact: {model_path}")

    # =========================
    # HEALTHY TENSOR
    # =========================
    if os.path.exists(healthy_tensor_path):
        try:
            healthy_tensor = torch.load(
                healthy_tensor_path,
                map_location="cpu",
                weights_only=False
            )

            if not isinstance(healthy_tensor, torch.Tensor):
                healthy_tensor = torch.tensor(healthy_tensor, dtype=torch.float32)

            if healthy_tensor.ndim == 1:
                healthy_tensor = healthy_tensor.reshape(1, -1)

            if healthy_tensor.shape[1] != len(gene_cols):
                print("⚠️ healthy_tensor shape does not match gene_cols")
                print("⚠️ Using zero healthy tensor temporarily")
                healthy_tensor = torch.zeros((1, len(gene_cols)), dtype=torch.float32)

            print("✅ healthy_tensor loaded successfully")

        except Exception as e:
            print("⚠️ Failed to load healthy_tensor.pt:", str(e))
            print("⚠️ Using zero healthy tensor temporarily")
            healthy_tensor = torch.zeros((1, len(gene_cols)), dtype=torch.float32)

    else:
        print("⚠️ healthy_tensor.pt not found, using zero healthy tensor temporarily")
        healthy_tensor = torch.zeros((1, len(gene_cols)), dtype=torch.float32)

    # =========================
    # MODEL
    # =========================
    model = DeepDenoisingAE(
        input_dim=len(gene_cols),
        latent_dim=64
    )

    state = torch.load(
        model_path,
        map_location="cpu",
        weights_only=False
    )

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
        if df.shape[1] <= 1:
            df = pd.read_csv(file_path)
    except Exception:
        df = pd.read_csv(file_path)

    df.columns = [str(c).strip() for c in df.columns]

    print("🧬 Uploaded gene file columns:")
    print(df.columns.tolist()[:30])
    print("🧬 Uploaded gene file shape:", df.shape)

    gene_col = None
    for col in [
        "GeneSymbol",
        "Hugo_Symbol",
        "gene",
        "GENE",
        "symbol",
        "gene_name",
        "GeneName",
        "gene_symbol",
        "Gene_Symbol",
    ]:
        if col in df.columns:
            gene_col = col
            break

    if gene_col is not None:
        expr_cols = [c for c in df.columns if c != gene_col]

        if not expr_cols:
            raise ValueError("No expression columns found in patient gene file.")

        df[gene_col] = df[gene_col].astype(str).str.strip().str.upper()
        df = df.drop_duplicates(subset=[gene_col])

        mat = df.set_index(gene_col)[expr_cols].apply(
            pd.to_numeric,
            errors="coerce"
        )

        first_sample = mat.columns[0]
        patient_vec = mat[first_sample]

        print("✅ Detected LONG gene file format")
        return patient_vec

    if df.empty:
        raise ValueError("Uploaded patient gene file is empty.")

    numeric_df = df.apply(pd.to_numeric, errors="coerce").fillna(0)

    first_row = numeric_df.iloc[0]
    first_row.index = [
        str(col).strip().upper()
        for col in first_row.index
    ]

    print("✅ Detected WIDE gene file format")
    return first_row


def build_patient_tensor(patient_vec, gene_cols, twin_scaler):
    """
    Equivalent to your build_patient_vector idea, but adapted to this runtime file.

    Input:
    - patient_vec: pandas Series where index = gene symbols and value = expression
    - gene_cols: trained model gene order
    - twin_scaler: trained scaler artifact

    Output:
    - torch tensor shaped (1, number_of_genes)
    """
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


def fetch_from_dgidb(drug_name):
    """
    Fetch drug-gene targets from DGIdb GraphQL.

    Returns:
    - list of uppercase gene symbols
    - [] if the drug is not found or the request fails
    """
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
            "drugName": str(drug_name).upper().strip()
        }

        response = requests.post(
            url,
            json={
                "query": query,
                "variables": variables
            },
            timeout=15
        )

        print("DGIdb STATUS:", response.status_code)
        print("DGIdb TEXT:", response.text[:500])

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
                genes.append(str(gene_name).upper().strip())

        return sorted(set(genes))

    except Exception as e:
        print("DGIdb GraphQL failed:", e)
        return []


def normalize_gene_targets(targets):
    clean_targets = []

    for gene in targets or []:
        if gene is None:
            continue

        gene = str(gene).strip().upper()

        if gene:
            clean_targets.append(gene)

    return sorted(set(clean_targets))


def resolve_targets_with_dgidb(twin, drug_name, cache=None):
    """
    Target resolution order:
    1. Use local artifact targets through twin._resolve_targets(drug_name)
    2. If no usable model targets are found, fetch targets from DGIdb
    3. Keep only targets that exist in twin.idx for simulation

    Returns:
    {
        "drug_name": str,
        "source": "artifact" | "dgidb" | "none",
        "all_targets": list,
        "valid_targets": list
    }
    """
    cache_key = str(drug_name).strip().lower()

    if cache is not None and cache_key in cache:
        return cache[cache_key]

    artifact_targets = normalize_gene_targets(twin._resolve_targets(drug_name))
    artifact_valid_targets = [g for g in artifact_targets if g in twin.idx]

    if artifact_valid_targets:
        result = {
            "drug_name": drug_name,
            "source": "artifact",
            "all_targets": artifact_targets,
            "valid_targets": artifact_valid_targets,
        }

        if cache is not None:
            cache[cache_key] = result

        return result

    dgidb_targets = fetch_from_dgidb(drug_name)
    dgidb_targets = normalize_gene_targets(dgidb_targets)
    dgidb_valid_targets = [g for g in dgidb_targets if g in twin.idx]

    # Optional: update the DigitalTwin object's local map during this runtime call.
    # This does not permanently modify drug_to_targets.pkl.
    if hasattr(twin, "drug_map") and dgidb_targets:  
        try:
            twin.drug_map[str(drug_name).strip().lower()] = dgidb_targets
            twin.drug_map[str(drug_name).strip().upper()] = dgidb_targets
            twin.drug_map[str(drug_name).strip()] = dgidb_targets
        except Exception as e:
            print("Could not update runtime drug_to_targets map:", e)

    if dgidb_valid_targets:
        source = "dgidb"
    else:
        source = "none"

    result = {
        "drug_name": drug_name,
        "source": source,
        "all_targets": dgidb_targets if dgidb_targets else artifact_targets,
        "valid_targets": dgidb_valid_targets,
    }

    if cache is not None:
        cache[cache_key] = result

    return result


def clean_for_json(value):
    if value is None:
        return None

    if isinstance(value, pd.DataFrame):
        return clean_for_json(value.replace({np.nan: None}).to_dict(orient="records"))

    if isinstance(value, pd.Series):
        return clean_for_json(value.replace({np.nan: None}).to_dict())

    if isinstance(value, dict):
        return {
            str(k): clean_for_json(v)
            for k, v in value.items()
        }

    if isinstance(value, list):
        return [clean_for_json(v) for v in value]

    if isinstance(value, tuple):
        return [clean_for_json(v) for v in value]

    if isinstance(value, np.ndarray):
        return clean_for_json(value.tolist())

    if isinstance(value, np.integer):
        return int(value)

    if isinstance(value, np.floating):
        if np.isnan(value):
            return None
        return float(value)

    if isinstance(value, float):
        if math.isnan(value) or math.isinf(value):
            return None
        return value

    if pd.isna(value) and not isinstance(value, (str, bool)):
        return None

    return value

def build_xai_summary(
    model,
    twin,
    patient_tensor,
    patient_vec,
    gene_cols,
    pathways,
    best_recommendation
):
    if not best_recommendation:
        return {
            "available": False,
            "message": "No best recommendation available for XAI analysis."
        }

    if "drug_pair" in best_recommendation:
        best_drug = " + ".join(best_recommendation["drug_pair"])
    else:
        best_drug = (
            best_recommendation.get("drug")
            or best_recommendation.get("drug_name")
            or "Selected drug"
        )

    try:
        patient_array = patient_tensor.detach().cpu().numpy()

        X_for_xai = pd.DataFrame(
            patient_array,
            columns=gene_cols
        )

        X_for_xai = X_for_xai.replace([np.inf, -np.inf], np.nan).fillna(0)

        patient_vec_safe = patient_vec.copy()
        patient_vec_safe.index = patient_vec_safe.index.astype(str).str.upper()
        patient_vec_safe = pd.to_numeric(patient_vec_safe, errors="coerce")
        patient_vec_safe = patient_vec_safe.replace([np.inf, -np.inf], np.nan).fillna(0)

        def predict_fn(data):
            arr = np.asarray(data, dtype=np.float32)
            arr = np.nan_to_num(arr, nan=0.0, posinf=0.0, neginf=0.0)

            outputs = []

            for row in arr:
                row_tensor = torch.tensor(
                    row.reshape(1, -1),
                    dtype=torch.float32
                )

                with torch.no_grad():
                    score = twin.calculate_risk(
                        model,
                        row_tensor
                    ).item()

                if np.isnan(score) or np.isinf(score):
                    score = 0.0

                outputs.append(float(score))

            return np.array(outputs)

        xai_result = run_xai_analysis(
            model=predict_fn,
            X=X_for_xai,
            patient_vec=patient_vec_safe,
            pathways=pathways,
            best_drug=best_drug
        )

        return clean_for_json({
            "available": True,
            "best_drug": best_drug,
            "top_genes": xai_result.get("top_genes", []),
            "top_pathways": xai_result.get("top_pathways", []),
            "reason_parts": xai_result.get("reason_parts", []),
            "final_explanation": xai_result.get("final_explanation", ""),
        })

    except Exception as e:
        print("⚠️ XAI analysis failed:", str(e))

        return {
            "available": False,
            "best_drug": best_drug,
            "message": f"XAI explanation could not be generated: {str(e)}"
        }
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

    target_cache = {}

    # Resolve all drug targets once.
    # This avoids calling DGIdb repeatedly during pair simulation.
    resolved_targets = {
        drug: resolve_targets_with_dgidb(
            twin=twin,
            drug_name=drug,
            cache=target_cache,
        )
        for drug in drugs
    }

    single_results = []

    for drug in drugs:
        target_info = resolved_targets[drug]
        valid_targets = target_info["valid_targets"]

        if not valid_targets:
            single_results.append({
                "drug_name": drug,
                "status": "no valid targets found",
                "target_source": target_info["source"],
                "all_targets": target_info["all_targets"],
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
            "target_source": target_info["source"],
            "baseline_risk": baseline_risk,
            "after_risk": after_risk,
            "risk_reduction_pct": risk_reduction_pct,
            "all_targets": target_info["all_targets"],
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

            targets_a = resolved_targets[drug_a]["valid_targets"]
            targets_b = resolved_targets[drug_b]["valid_targets"]

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
                "target_sources": {
                    drug_a: resolved_targets[drug_a]["source"],
                    drug_b: resolved_targets[drug_b]["source"],
                },
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
    xai_summary = build_xai_summary(
    model=model,
    twin=twin,
    patient_tensor=patient_tensor,
    patient_vec=patient_vec,
    gene_cols=gene_cols,
    pathways=PATHWAYS,
    best_recommendation=best_recommendation
)
    rank_path = os.path.join(ARTIFACT_DIR, "fused_single.csv")

    if os.path.exists(rank_path):
        df_rank = pd.read_csv(rank_path)
        fusion_df = fuse_results(
    single_results=single_results,
    pair_results=pair_results,
    df_rank=df_rank,
    input_drugs=drugs
)
        fusion_results = clean_for_json(fusion_df.to_dict(orient="records"))
    else:
        fusion_results = []

    return clean_for_json({
        "input_drugs": drugs,
        "baseline_risk": baseline_risk,
        "resolved_targets": resolved_targets,
        "single_results": single_results,
        "pair_results": pair_results,
        "fusion_results": fusion_results,
        "best_recommendation": best_recommendation,
        "xai_summary": xai_summary,
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


def fuse_results(single_results, pair_results, df_rank, input_drugs=None):
    """
    Combines ranking model score + TwinSimulation score + pair bonus.
    Returns only the drugs selected/searched by the user if input_drugs is provided.

    df_rank should contain at least:
    drug_name or drug_name_norm
    final_score
    score_conf
    """

    if df_rank is None or df_rank.empty:
        return pd.DataFrame()

    rank_map = df_rank.copy()

    # =========================
    # NORMALIZE DRUG NAME COLUMN
    # =========================
    if "drug_name" not in rank_map.columns:
        if "drug_name_norm" in rank_map.columns:
            rank_map["drug_name"] = rank_map["drug_name_norm"]
        elif "drug" in rank_map.columns:
            rank_map["drug_name"] = rank_map["drug"]
        else:
            raise ValueError("df_rank must contain drug_name, drug_name_norm, or drug column")

    rank_map["drug_name"] = (
        rank_map["drug_name"]
        .astype(str)
        .str.strip()
        .str.lower()
    )

    # =========================
    # REQUIRED SCORE COLUMNS
    # =========================
    if "final_score" not in rank_map.columns:
        rank_map["final_score"] = 0

    if "score_conf" not in rank_map.columns:
        rank_map["score_conf"] = 0

    rank_map["final_score"] = pd.to_numeric(
        rank_map["final_score"],
        errors="coerce"
    ).fillna(0)

    rank_map["score_conf"] = pd.to_numeric(
        rank_map["score_conf"],
        errors="coerce"
    ).fillna(0)

    # Important:
    # Calculate minmax BEFORE filtering, so one selected drug does not always become 0.
    rank_map["rank_score"] = minmax(rank_map["final_score"])
    rank_map["conf_score"] = minmax(rank_map["score_conf"])

    # =========================
    # SINGLE TWIN RESULTS
    # =========================
    valid_single_results = [
        item for item in single_results
        if "risk_reduction_pct" in item
    ]

    single_df = pd.DataFrame(valid_single_results)

    if not single_df.empty:
        single_df["drug_name"] = (
            single_df["drug_name"]
            .astype(str)
            .str.strip()
            .str.lower()
        )

        single_df["risk_reduction_pct"] = pd.to_numeric(
            single_df["risk_reduction_pct"],
            errors="coerce"
        ).fillna(0)

        single_df["twin_score"] = minmax(single_df["risk_reduction_pct"])

        single_keep_cols = [
            "drug_name",
            "risk_reduction_pct",
            "twin_score",
            "pathway_hits",
            "valid_targets",
        ]

        single_df = single_df[
            [col for col in single_keep_cols if col in single_df.columns]
        ]

    else:
        single_df = pd.DataFrame(
            columns=["drug_name", "risk_reduction_pct", "twin_score"]
        )

    # =========================
    # PAIR / COMBINATION BONUS
    # =========================
    pair_df = pd.DataFrame(pair_results)
    pair_expanded = []

    if not pair_df.empty and "risk_reduction_pct" in pair_df.columns:
        pair_df["risk_reduction_pct"] = pd.to_numeric(
            pair_df["risk_reduction_pct"],
            errors="coerce"
        ).fillna(0)

        pair_df["pair_score"] = minmax(pair_df["risk_reduction_pct"])

        for _, r in pair_df.iterrows():
            if "drug_pair" not in r or not isinstance(r["drug_pair"], list):
                continue

            if len(r["drug_pair"]) < 2:
                continue

            drug_a, drug_b = r["drug_pair"]

            pair_expanded.append({
                "drug_name": str(drug_a).strip().lower(),
                "pair_bonus": r["pair_score"]
            })

            pair_expanded.append({
                "drug_name": str(drug_b).strip().lower(),
                "pair_bonus": r["pair_score"]
            })

    pair_bonus_df = pd.DataFrame(pair_expanded)

    if not pair_bonus_df.empty:
        pair_bonus_df = pair_bonus_df.groupby(
            "drug_name",
            as_index=False
        )["pair_bonus"].max()
    else:
        pair_bonus_df = pd.DataFrame(columns=["drug_name", "pair_bonus"])

    # =========================
    # MERGE SCORES
    # =========================
    merged = rank_map.merge(single_df, on="drug_name", how="left")
    merged = merged.merge(pair_bonus_df, on="drug_name", how="left")

    merged["twin_score"] = merged["twin_score"].fillna(0)
    merged["pair_bonus"] = merged["pair_bonus"].fillna(0)

    if "risk_reduction_pct" not in merged.columns:
        merged["risk_reduction_pct"] = 0

    merged["risk_reduction_pct"] = pd.to_numeric(
        merged["risk_reduction_pct"],
        errors="coerce"
    ).fillna(0)

    # =========================
    # FUSION SCORE
    # =========================
    cfg = FusionConfig()

    merged["fusion_score"] = (
        cfg.w_rank * merged["rank_score"] +
        cfg.w_twin * merged["twin_score"] +
        cfg.w_pair_bonus * merged["pair_bonus"] +
        cfg.w_conf * merged["conf_score"]
    )

    # =========================
    # FILTER ONLY USER SEARCHED DRUGS
    # =========================
    if input_drugs:
        input_drugs_norm = [
            str(drug).strip().lower()
            for drug in input_drugs
            if str(drug).strip()
        ]

        merged = merged[
            merged["drug_name"].isin(input_drugs_norm)
        ]

    # =========================
    # RETURN ONLY USEFUL COLUMNS
    # =========================
    useful_cols = [
        "drug_name",
        "fusion_score",
        "final_score",
        "rank_score",
        "score_conf",
        "conf_score",
        "risk_reduction_pct",
        "twin_score",
        "pair_bonus",
        "pathway_hits",
        "valid_targets",
        "top_pathway",
        "pathway_coverage_score",
    ]

    existing_cols = [
        col for col in useful_cols
        if col in merged.columns
    ]

    merged = merged[existing_cols]

    return merged.sort_values("fusion_score", ascending=False)