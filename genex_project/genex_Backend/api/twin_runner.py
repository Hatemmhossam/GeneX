import os
import numpy as np
import pandas as pd

from api.digital_twin import PipelineConfig, run_therapy_pipeline


def clean_for_json(value):
    if isinstance(value, pd.DataFrame):
        return value.replace({np.nan: None}).to_dict(orient="records")

    if isinstance(value, pd.Series):
        return value.replace({np.nan: None}).to_dict()

    if isinstance(value, dict):
        cleaned = {}
        skip_keys = {
            "patient_df",
            "patient_mat",
            "patient_vec",
            "patient_z",
            "immune_map",
            "master_df",
            "healthy_expr",
            "X_master_scaled",
            "healthy_scaled",
            "twin_model",
            "healthy_tensor",
            "patient_tensor",
            "training_artifacts",
            "twin_fit",
            "twin_reference",
            "patient_twin",
        }

        for key, val in value.items():
            if key in skip_keys:
                continue
            cleaned[key] = clean_for_json(val)

        return cleaned

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


def get_required_path(env_name):
    path = os.getenv(env_name)

    if not path:
        raise ValueError(f"{env_name} is missing from .env")

    if not os.path.exists(path):
        raise ValueError(f"{env_name} file does not exist: {path}")

    return path


def run_full_twin_pipeline_for_user(user, drugs=None):
    if not getattr(user, "current_gene_file", None):
        raise ValueError("No active gene expression file found for this user.")

    patient_expr_path = user.current_gene_file.file.path

    config = PipelineConfig(
        patient_expr_path=patient_expr_path,
        immune_map_path=get_required_path("TWIN_IMMUNE_MAP_PATH"),
        prism_dose_response_path=get_required_path("TWIN_PRISM_PATH"),
        ccle_expr_path=get_required_path("TWIN_CCLE_PATH"),
        twin_master_df_path=get_required_path("TWIN_MASTER_DF_PATH"),
        dgidb_cache_path=os.getenv("TWIN_DGIDB_CACHE_PATH", ""),
    )

    results = run_therapy_pipeline(
        config=config,
        patient_expr_path=patient_expr_path,
        patient_sample=None,
        patient_sample_index=5,
        candidate_drugs=drugs,
    )

    return {
        "input_drugs": drugs or [],
        "fused_single": clean_for_json(results.get("fused_single", pd.DataFrame()).head(20)),
        "combo_rank": clean_for_json(results.get("combo_rank", pd.DataFrame()).head(20)),
        "twin_single": clean_for_json(results.get("twin_single", pd.DataFrame()).head(20)),
        "twin_pairs": clean_for_json(results.get("twin_pairs", pd.DataFrame()).head(20)),
        "baseline_pathways": clean_for_json(results.get("baseline_pathways", pd.DataFrame())),
        "genes_for_model_count": len(results.get("genes_for_model", [])),
    }