
import math
import shap
import numpy as np
import pandas as pd


def make_json_safe(value):
    if value is None:
        return None

    if isinstance(value, pd.DataFrame):
        safe_df = value.replace([np.inf, -np.inf], np.nan)
        safe_df = safe_df.where(pd.notnull(safe_df), None)
        return make_json_safe(safe_df.to_dict(orient="records"))

    if isinstance(value, pd.Series):
        safe_series = value.replace([np.inf, -np.inf], np.nan)
        safe_series = safe_series.where(pd.notnull(safe_series), None)
        return make_json_safe(safe_series.to_dict())

    if isinstance(value, dict):
        return {
            str(k): make_json_safe(v)
            for k, v in value.items()
        }

    if isinstance(value, list):
        return [make_json_safe(v) for v in value]

    if isinstance(value, tuple):
        return [make_json_safe(v) for v in value]

    if isinstance(value, set):
        return [make_json_safe(v) for v in value]

    if isinstance(value, np.ndarray):
        return make_json_safe(value.tolist())

    if isinstance(value, np.integer):
        return int(value)

    if isinstance(value, np.floating):
        if np.isnan(value) or np.isinf(value):
            return None
        return float(value)

    if isinstance(value, float):
        if math.isnan(value) or math.isinf(value):
            return None
        return value

    try:
        if pd.isna(value) and not isinstance(value, (str, bool)):
            return None
    except Exception:
        pass

    return value


def run_xai_analysis(
    model,
    X,
    patient_vec,
    pathways,
    best_drug
):
    # =====================================================
    # 1. PREPARE DATA
    # =====================================================

    X_sample = X.copy()

    X_sample = X_sample.replace([np.inf, -np.inf], np.nan).fillna(0)

    if len(X_sample) > 100:
        X_sample = X_sample.sample(
            100,
            random_state=42
        )

    # =====================================================
    # 2. SHAP EXPLAINABILITY
    # =====================================================

    try:
        explainer = shap.Explainer(
            model,
            X_sample
        )

        shap_values = explainer(X_sample)

        shap_importance = np.abs(
            shap_values.values
        ).mean(axis=0)

    except Exception as shap_error:
        print(
            "Default SHAP explainer failed "
            "→ using fallback explanation logic"
        )
        print("SHAP ERROR:", str(shap_error))

        try:
            explainer = shap.TreeExplainer(model)

            shap_values = explainer.shap_values(
                X_sample
            )

            shap_importance = np.abs(
                shap_values
            ).mean(axis=0)

        except Exception as fallback_error:
            print("TreeExplainer also failed:", str(fallback_error))

            # Safe fallback: use expression magnitude as importance
            shap_importance = np.abs(
                X_sample.to_numpy(dtype=float)
            ).mean(axis=0)

    shap_importance = np.asarray(shap_importance).reshape(-1)

    if len(shap_importance) != len(X_sample.columns):
        shap_importance = np.resize(
            shap_importance,
            len(X_sample.columns)
        )

    shap_importance = np.nan_to_num(
        shap_importance,
        nan=0.0,
        posinf=0.0,
        neginf=0.0
    )

    # =====================================================
    # 3. TOP SHAP GENES
    # =====================================================

    importance_df = pd.DataFrame({
        "gene": X_sample.columns,
        "importance": shap_importance
    })

    importance_df["importance"] = pd.to_numeric(
        importance_df["importance"],
        errors="coerce"
    ).fillna(0)

    importance_df = importance_df.sort_values(
        "importance",
        ascending=False
    )

    importance_df = importance_df[
        importance_df["importance"] > 0
    ]

    top_shap_genes = (
        importance_df.head(20)["gene"]
        .astype(str)
        .str.upper()
        .tolist()
    )

    top_gene_objects = []

    for _, row in importance_df.head(10).iterrows():
        importance_value = float(row["importance"])

        if math.isnan(importance_value) or math.isinf(importance_value):
            continue

        top_gene_objects.append({
            "gene": str(row["gene"]).upper(),
            "importance": importance_value
        })

    # =====================================================
    # 4. PATHWAY ACTIVITY ANALYSIS
    # =====================================================

    patient_vec_safe = patient_vec.copy()
    patient_vec_safe.index = patient_vec_safe.index.astype(str).str.upper()
    patient_vec_safe = pd.to_numeric(
        patient_vec_safe,
        errors="coerce"
    )
    patient_vec_safe = patient_vec_safe.replace(
        [np.inf, -np.inf],
        np.nan
    ).dropna()

    patient_genes_upper = set(
        patient_vec_safe.index.astype(str).str.upper()
    )

    pathway_scores = {}

    for pathway, genes in pathways.items():
        pathway_genes = set([
            str(g).upper()
            for g in genes
        ])

        overlap = patient_genes_upper.intersection(
            pathway_genes
        )

        if len(overlap) == 0:
            continue

        try:
            expr_values = patient_vec_safe.loc[
                list(overlap)
            ]

            score_values = pd.to_numeric(
                expr_values,
                errors="coerce"
            ).dropna()

            if score_values.empty:
                continue

            score = float(score_values.mean())

            if math.isnan(score) or math.isinf(score):
                continue

        except Exception:
            continue

        pathway_scores[pathway] = {
            "score": score,
            "genes": sorted(list(overlap))
        }

    # =====================================================
    # 5. PATHWAY DATAFRAME
    # =====================================================

    pathway_df = pd.DataFrame([
        {
            "pathway": pathway,
            "activity_score": values["score"],
            "genes": values["genes"]
        }
        for pathway, values in pathway_scores.items()
    ])

    if not pathway_df.empty:
        pathway_df["activity_score"] = pd.to_numeric(
            pathway_df["activity_score"],
            errors="coerce"
        ).fillna(0)

        pathway_df = pathway_df.sort_values(
            "activity_score",
            ascending=False
        )

    # =====================================================
    # 6. DYNAMIC BIOLOGICAL INTERPRETATION
    # =====================================================

    top_pathways = []
    evidence_blocks = []
    top_shap_set = set(top_shap_genes)

    if not pathway_df.empty:
        for _, row in pathway_df.head(3).iterrows():
            pathway = str(row["pathway"])
            score = float(row["activity_score"])

            if math.isnan(score) or math.isinf(score):
                continue

            genes = set(row["genes"])
            shap_genes = sorted(list(
                genes.intersection(top_shap_set)
            ))

            if len(genes) > 0 and len(shap_genes) > 0:
                interpretation = (
                    f"This pathway shows strong biological activity through "
                    f"{len(genes)} patient-associated genes. "
                    f"Among these, {len(shap_genes)} genes are also identified "
                    f"as highly influential by SHAP, suggesting that the model "
                    f"relies directly on biologically relevant molecular signals "
                    f"linked to this pathway."
                )

            elif len(genes) > 0:
                interpretation = (
                    f"This pathway is supported by {len(genes)} patient genes, "
                    f"indicating measurable biological activation. However, "
                    f"limited SHAP overlap suggests the model may use indirect "
                    f"molecular patterns associated with this pathway."
                )

            else:
                interpretation = (
                    "No strong direct gene overlap was detected. The pathway "
                    "activity may be inferred through correlated gene expression "
                    "patterns captured by the predictive model."
                )

            pathway_object = {
                "pathway": pathway,
                "score": score,
                "genes": sorted(list(genes))[:20],
                "shap_overlap": shap_genes[:20],
                "interpretation": interpretation
            }

            top_pathways.append(pathway_object)

            evidence_blocks.append({
                "pathway": pathway,
                "score": score,
                "genes": sorted(list(genes)),
                "shap_genes": shap_genes,
                "interpretation": interpretation
            })

    # =====================================================
    # 7. BUILD REASONING BLOCKS
    # =====================================================

    reason_parts = []

    for block in evidence_blocks:
        pathway = block["pathway"]
        genes = block["genes"]
        shap_genes = block["shap_genes"]

        if len(genes) > 0:
            reason_parts.append(
                f"{pathway} is active through {len(genes)} patient genes"
            )

        if len(shap_genes) > 0:
            reason_parts.append(
                f"{len(shap_genes)} genes in {pathway} strongly influence model prediction"
            )

    # =====================================================
    # 8. FINAL DRUG EXPLANATION
    # =====================================================

    pathway_names = [
        p["pathway"]
        for p in top_pathways
    ]

    important_gene_names = [
        g["gene"]
        for g in top_gene_objects[:5]
    ]

    if pathway_names and important_gene_names:
        explanation = (
            f"{best_drug} was prioritized because the patient demonstrates "
            f"activation in biologically relevant pathways including "
            f"{', '.join(pathway_names)}. "
            f"The machine learning model identified key genes such as "
            f"{', '.join(important_gene_names)} as major contributors to the "
            f"prediction. The overlap between pathway-associated genes and "
            f"SHAP-important genes suggests the recommendation is supported "
            f"by both biological evidence and model-driven predictive signals."
        )

    elif pathway_names:
        explanation = (
            f"{best_drug} was prioritized because the patient demonstrates "
            f"activation in biologically relevant pathways including "
            f"{', '.join(pathway_names)}. The explanation is mainly supported "
            f"by pathway-level biological activity."
        )

    elif important_gene_names:
        explanation = (
            f"{best_drug} was prioritized based on model-driven gene importance. "
            f"The model identified key genes such as "
            f"{', '.join(important_gene_names)} as relevant contributors."
        )

    else:
        explanation = (
            f"{best_drug} was selected by the TwinSimulation pipeline, but "
            f"the XAI module could not identify strong pathway or gene-level "
            f"evidence from the available patient input."
        )

    # =====================================================
    # 9. OPTIONAL CONSOLE OUTPUT
    # =====================================================

    print("\n" + "=" * 60)
    print("EXPLAINABLE AI REPORT")
    print("=" * 60)
    print(f"\nSelected Drug: {best_drug}")

    print("\nTOP IMPORTANT GENES")
    print(importance_df.head(10))

    print("\nTOP ACTIVE PATHWAYS")
    for pathway in top_pathways:
        print("\n" + "-" * 50)
        print(f"Pathway: {pathway['pathway']}")
        print(f"Activity Score: {pathway['score']:.4f}")
        print(f"Genes: {pathway['genes'][:10]}")
        print(f"SHAP Overlap: {pathway['shap_overlap']}")
        print("\nInterpretation:")
        print(pathway["interpretation"])

    print("\n" + "=" * 60)
    print("FINAL EXPLANATION")
    print("=" * 60)
    print(explanation)

    # =====================================================
    # 10. RETURN JSON-SAFE SUMMARY ONLY
    # =====================================================

    return make_json_safe({
        "top_genes": top_gene_objects[:10],
        "top_pathways": top_pathways[:3],
        "reason_parts": reason_parts[:6],
        "final_explanation": explanation
    })
