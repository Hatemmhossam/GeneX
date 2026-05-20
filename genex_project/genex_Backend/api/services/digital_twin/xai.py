import shap
import numpy as np
import pandas as pd


def run_xai_analysis(
    model,
    X,
    patient_vec,
    pathways,
    best_drug
):

    # -----------------------------
    # SHAP
    # -----------------------------
    X_sample = X.copy()

    if len(X_sample) > 100:
        X_sample = X_sample.sample(100, random_state=42)

    try:
        explainer = shap.Explainer(model, X_sample)
        shap_values = explainer(X_sample)

        shap_importance = np.abs(
            shap_values.values
        ).mean(axis=0)

    except Exception:

        explainer = shap.TreeExplainer(model)

        shap_values = explainer.shap_values(X_sample)

        shap_importance = np.abs(
            shap_values
        ).mean(axis=0)

    # -----------------------------
    # TOP SHAP GENES
    # -----------------------------
    xai_df = pd.DataFrame({
        "gene": X_sample.columns,
        "shap_value": shap_importance
    }).sort_values(
        "shap_value",
        ascending=False
    )

    top_shap_genes = (
        xai_df.head(20)["gene"]
        .astype(str)
        .str.upper()
        .tolist()
    )

    top_gene_objects = []

    for _, row in xai_df.head(15).iterrows():

        top_gene_objects.append({
            "gene": str(row["gene"]),
            "importance": float(row["shap_value"])
        })

    # -----------------------------
    # PATHWAY ACTIVITY
    # -----------------------------
    patient_genes = set(
        patient_vec.index
        .astype(str)
        .str.upper()
    )

    pathway_scores = {}

    for pathway, genes in pathways.items():

        pathway_genes = set([
            str(g).upper()
            for g in genes
        ])

        overlap = patient_genes.intersection(
            pathway_genes
        )

        if len(overlap) == 0:
            continue

        expr_values = patient_vec.loc[list(overlap)]

        score = float(expr_values.mean())

        pathway_scores[pathway] = {
            "score": score,
            "genes": list(overlap)
        }

    pathway_df = pd.DataFrame([
        {
            "pathway": k,
            "activity_score": v["score"],
            "genes": v["genes"]
        }
        for k, v in pathway_scores.items()
    ])

    if len(pathway_df) > 0:
        pathway_df = pathway_df.sort_values(
            "activity_score",
            ascending=False
        )

    top_pathways = []

    evidence_blocks = []

    top_shap_set = set(top_shap_genes)

    # -----------------------------
    # INTEGRATED EXPLANATION
    # -----------------------------
    for _, row in pathway_df.head(3).iterrows():

        pathway = row["pathway"]

        score = float(row["activity_score"])

        genes = set(row["genes"])

        shap_genes = list(
            genes.intersection(top_shap_set)
        )

        pathway_object = {
            "pathway": pathway,
            "score": score,
            "genes": list(genes),
            "shap_overlap": shap_genes,
            "interpretation":
                interpret_pathway(score)
        }

        top_pathways.append(pathway_object)

        evidence_blocks.append({
            "pathway": pathway,
            "score": score,
            "genes": list(genes),
            "shap_genes": shap_genes
        })

    # -----------------------------
    # DRUG EXPLANATION
    # -----------------------------
    reason_parts = []

    for block in evidence_blocks:

        pathway = block["pathway"]

        genes = block["genes"]

        shap_genes = block["shap_genes"]

        if len(genes) > 0:

            reason_parts.append(
                f"{pathway} is active through "
                f"{len(genes)} genes"
            )

        if len(shap_genes) > 0:

            reason_parts.append(
                f"{len(shap_genes)} genes in "
                f"{pathway} influence "
                f"model prediction"
            )

    explanation = (
        f"The drug {best_drug} is selected "
        f"because it aligns with the "
        f"patient's active pathways and "
        f"the model-important genes."
    )

    # -----------------------------
    # RETURN EVERYTHING
    # -----------------------------
    return {

        "top_genes": top_gene_objects,

        "top_pathways": top_pathways,

        "reason_parts": reason_parts,

        "final_explanation": explanation
    }


def interpret_pathway(score):

    if score > 2:
        return "Highly activated pathway"

    elif score > 1:
        return "Moderately active pathway"

    return "Low pathway activity"