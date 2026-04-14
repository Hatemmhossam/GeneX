from .twin_core import PipelineConfig, run_therapy_pipeline


def run_twin_simulation(gene_file_path, drugs):

    # Create config
    config = PipelineConfig()

    # Override ONLY patient file
    result = run_therapy_pipeline(
        config=config,
        patient_expr_path=gene_file_path,   # ← from user upload
        candidate_drugs=drugs              # ← from frontend
    )

    # Extract only what frontend needs
    return {
        "top_single_drugs": result["fused_single"].head(10).to_dict(orient="records")
        if not result["fused_single"].empty else [],

        "top_combinations": result["combo_rank"].head(10).to_dict(orient="records")
        if not result["combo_rank"].empty else [],

        "twin_single": result["twin_single"].to_dict(orient="records")
        if not result["twin_single"].empty else [],

        "twin_pairs": result["twin_pairs"].to_dict(orient="records")
        if not result["twin_pairs"].empty else []
    }