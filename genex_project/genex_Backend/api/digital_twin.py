
# Imports, configuration, and reproducibility
import os
import re
import json
import math
import random
import warnings
from dataclasses import dataclass, asdict
from itertools import combinations
from typing import Dict, List, Optional, Tuple, Any

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

import gseapy as gp

from sklearn.base import clone
from sklearn.model_selection import KFold
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
from sklearn.linear_model import ElasticNet, Ridge, Lasso
from sklearn.ensemble import RandomForestRegressor, ExtraTreesRegressor, GradientBoostingRegressor
from sklearn.preprocessing import StandardScaler, RobustScaler
from scipy.stats import pearsonr, spearmanr

XGBOOST_AVAILABLE = False
try:
    from xgboost import XGBRegressor
    XGBOOST_AVAILABLE = True
except Exception:
    pass

DGIPY_AVAILABLE = False
try:
    import dgipy
    DGIPY_AVAILABLE = True
except Exception:
    pass

TORCH_AVAILABLE = False
try:
    import torch
    import torch.nn as nn
    TORCH_AVAILABLE = True
except Exception:
    pass

warnings.filterwarnings("ignore")

SEED = 42
random.seed(SEED)
np.random.seed(SEED)
if TORCH_AVAILABLE:
    torch.manual_seed(SEED)
    if torch.cuda.is_available():
        torch.cuda.manual_seed_all(SEED)
        torch.backends.cudnn.deterministic = True

DEVICE = "cuda" if TORCH_AVAILABLE and torch.cuda.is_available() else "cpu"



@dataclass
class PipelineConfig:

    patient_expr_path: str = "/content/drive/MyDrive/genesExpression/RABC13_Level3.txt"
    immune_map_path: str = "/content/drive/MyDrive/AI03 GP/twin files/immune_gene_network (1) (1).csv"
    prism_dose_response_path: str = "/content/drive/MyDrive/AI03 GP/twin files/secondary-screen-dose-response-curve-parameters.csv"
    ccle_expr_path: str = "/content/drive/MyDrive/AI03 GP/twin files/CCLE_expression.csv"
    twin_master_df_path: str = "/content/drive/MyDrive/AI03 GP/twin files/master_df.csv"
    dgidb_cache_path: str = "/content/drive/MyDrive/dgidb_interactions_cache.csv"

    top_n: int = 25
    min_rows: int = 60
    cv_folds: int = 5
    random_state: int = 42
    min_acceptable_r2: float = -0.25

    # Layer 1 weights
    w_targets: float = 0.35
    w_ic50: float = 0.30
    w_model: float = 0.20
    w_conf: float = 0.15

    # Twin config
    healthy_label_values: Tuple[str, ...] = ("healthy", "control", "normal")
    twin_latent_dim: int = 64
    twin_epochs: int = 250
    twin_lr: float = 1e-3
    sim_top_k_drugs: int = 6
    sim_base_alpha: float = 0.45
    sim_pair_extra_alpha: float = 0.10
    top_changed_genes: int = 8

    # Fusion weights
    fusion_w_rank: float = 0.45
    fusion_w_twin: float = 0.35
    fusion_w_conf: float = 0.10
    fusion_w_path: float = 0.10

PATHWAYS = {

    "Inflammatory_Response": [
        "IL6",
        "TNF",
        "STAT3",
        "JAK1",
        "CXCL8",
        "NFKB1",
        "NFKBIA",
        "RELA",
        "IL1B",
        "PTGS2"
    ],

    "T_Cell_Activation": [
        "FOXP3",
        "CD28",
        "IL2RA",
        "CD4",
        "CD8A",
        "LCK",
        "ZAP70",
        "LAT",
        "FYN",
        "ITK",
        "CD3D",
        "CD3E",
        "CD247",
        "ICOS",
        "PDCD1",
        "CTLA4"
    ],

    "Antigen_Presentation": [
        "HLA-A",
        "HLA-B",
        "HLA-C",
        "HLA-DPB1",
        "HLA-DQB1",
        "B2M",
        "TAP1",
        "TAP2",
        "CIITA",
        "PSMB8"
    ],

    "JAK_STAT_Signaling": [
        "JAK1",
        "JAK2",
        "JAK3",
        "TYK2",
        "STAT1",
        "STAT2",
        "STAT3",
        "STAT4",
        "STAT5A",
        "STAT5B",
        "STAT6",
        "SOCS1",
        "SOCS3"
    ],

    "Apoptosis_Cell_Stress": [
        "BCL2",
        "BAX",
        "CASP3",
        "CASP8",
        "TP53",
        "MCL1",
        "FAS",
        "FADD",
        "BAD",
        "BID"
    ],

    "PI3K_AKT_MTOR": [
        "PIK3CA",
        "PIK3CB",
        "PIK3CD",
        "AKT1",
        "AKT2",
        "AKT3",
        "MTOR",
        "PTEN",
        "RPS6KB1",
        "EIF4EBP1",
        "EGFR"

    ],

    "MAPK_SIGNALING": [
        "KRAS",
        "NRAS",
        "HRAS",
        "BRAF",
        "RAF1",
        "MAP2K1",
        "MAP2K2",
        "MAPK1",
        "MAPK3",
        "EGFR"
    ],

    "CELL_CYCLE": [
        "CDK1",
        "CDK2",
        "CDK4",
        "CDK6",
        "CCND1",
        "CCNE1",
        "RB1",
        "E2F1",
        "MYC",
        "TP53"
    ],

    "DNA_REPAIR": [
        "BRCA1",
        "BRCA2",
        "ATM",
        "ATR",
        "CHEK1",
        "CHEK2",
        "PARP1",
        "RAD51",
        "TP53",
        "MLH1",
        "PARP2"
    ],

    "EMT_METASTASIS": [
        "VIM",
        "CDH1",
        "CDH2",
        "SNAI1",
        "SNAI2",
        "TWIST1",
        "ZEB1",
        "ZEB2"
    ],

    "HYPOXIA": [
        "HIF1A",
        "VEGFA",
        "LDHA",
        "SLC2A1",
        "CA9",
        "EPO"
    ],

    "INTERFERON_SIGNALING": [
        "IFNG",
        "IFNAR1",
        "IFNAR2",
        "STAT1",
        "STAT2",
        "IRF1",
        "IRF7",
        "MX1"
    ]
}

# normalize genes
def run_gsea(patient_vec, pathways):

    """
    Simple GSEA enrichment analysis.
    Used ONLY for interpretation.
    """

    import pandas as pd
    import numpy as np
    import gseapy as gp

    # -------------------------
    # CLEAN GENE NAMES
    # -------------------------

    patient_vec.index = patient_vec.index.astype(str).str.upper()

    ranked_genes = (
        patient_vec
        .dropna()
        .sort_values(ascending=False)
    )

    # remove duplicated genes
    ranked_genes = ranked_genes[
        ~ranked_genes.index.duplicated(keep="first")
    ]

    # tiny noise to avoid duplicate ranking values
    ranked_genes = ranked_genes + np.random.normal(
        0,
        1e-8,
        len(ranked_genes)
    )

    # -------------------------
    # CLEAN PATHWAYS
    # -------------------------

    cleaned_pathways = {}

    for pathway_name, genes in pathways.items():

        genes_upper = [
            str(g).upper()
            for g in genes
        ]

        overlap = [
            g for g in genes_upper
            if g in ranked_genes.index
        ]

        # IMPORTANT:
        # allow SMALL pathways
        if len(overlap) >= 2:
            cleaned_pathways[pathway_name] = overlap

    if len(cleaned_pathways) == 0:

        print("No valid pathways for GSEA.")
        return pd.DataFrame()

    # -------------------------
    # RUN GSEA
    # -------------------------

    try:

        res = gp.prerank(

            rnk=ranked_genes,

            gene_sets=cleaned_pathways,

            permutation_num=100,

            min_size=2,     # VERY IMPORTANT
            max_size=5000,

            seed=42,

            outdir=None,

            verbose=False
        )

        return res.res2d.reset_index()

    except Exception as e:

        print("GSEA failed:", e)

        return pd.DataFrame()
    
def compute_pathway_activity(patient_vec, pathways, ccle_reference=None):
    import numpy as np
    import pandas as pd

    patient_vec = patient_vec.copy()
    patient_vec = pd.to_numeric(patient_vec, errors="coerce")

    # remove ribosomal noise (important)
    ribosomal = [g for g in patient_vec.index if g.startswith("RPL") or g.startswith("RPS")]
    patient_vec = patient_vec.drop(ribosomal, errors="ignore")

    pathway_scores = []

    for pathway_name, genes in pathways.items():

        valid_genes = [g for g in genes if g in patient_vec.index]

        if len(valid_genes) < 2:
            continue

        patient_values = patient_vec.loc[valid_genes].dropna()

        if len(patient_values) == 0:
            continue

        # patient pathway score
        patient_score = np.median(patient_values)

        # 🔥 ADD POPULATION COMPARISON (KEY FIX)
        if ccle_reference is not None:
            ref_values = ccle_reference[valid_genes].mean(axis=1)
            baseline_score = ref_values.mean()

            score = patient_score - baseline_score
        else:
            score = patient_score

        pathway_scores.append({
            "pathway": pathway_name,
            "activity_score": score,
            "n_genes": len(valid_genes)
        })

    df = pd.DataFrame(pathway_scores)

    if not df.empty:
        df["normalized_activity"] = (
            df["activity_score"] - df["activity_score"].mean()
        ) / (df["activity_score"].std() + 1e-8)

    return df


def pick_col(df, candidates):
    for c in candidates:
        if c in df.columns:
            return c
    return None

def safe_upper_series(s):
    return s.astype(str).str.strip().str.upper()

def normalize_gene_symbol(x):
    return str(x).strip().upper()

def normalize_ccle_gene(col):
    col = str(col).strip().upper()
    col = re.sub(r"\s*\([^)]*\)\s*$", "", col)
    return col

DROP_TOKENS = {
    "hydrochloride", "hcl", "sodium", "acetate", "phosphate", "sulfate", "sulphate",
    "mesylate", "maleate", "tartrate", "tosylate", "hydrate", "monohydrate",
    "dihydrate", "trihydrate", "hemisulfate", "besylate"
}

def norm_basic(x):
    return str(x).strip().lower()

def norm_strong(x):
    x = str(x).strip().lower()
    x = re.sub(r"[^a-z0-9\s]", " ", x)
    toks = [t for t in x.split() if t not in DROP_TOKENS]
    return " ".join(toks).strip()

def chunk_list(lst, n=50):
    for i in range(0, len(lst), n):
        yield lst[i:i+n]

def rowwise_z(df: pd.DataFrame) -> pd.DataFrame:
    m = df.mean(axis=1)
    s = df.std(axis=1).replace(0, 1.0)
    return df.sub(m, axis=0).div(s, axis=0)

def minmax01(s):
    s = pd.Series(s, dtype=float)
    if len(s) == 0:
        return s
    if s.nunique(dropna=True) <= 1:
        return pd.Series(np.ones(len(s)), index=s.index)
    return (s - s.min()) / (s.max() - s.min())

def safe_corr(a, b, method="pearson"):
    a = np.asarray(a, dtype=float)
    b = np.asarray(b, dtype=float)
    if len(a) < 3 or np.std(a) == 0 or np.std(b) == 0:
        return np.nan
    try:
        if method == "pearson":
            return pearsonr(a, b)[0]
        return spearmanr(a, b)[0]
    except Exception:
        return np.nan

def model_needs_scaler(model_name):
    return model_name in {"elasticnet", "ridge", "lasso"}

def make_scaler_and_transform(X_train, X_valid, use_scaler=True):
    if not use_scaler:
        return None, X_train.values, X_valid.values
    scaler = StandardScaler()
    Xtr = scaler.fit_transform(X_train)
    Xva = scaler.transform(X_valid)
    return scaler, Xtr, Xva

def confidence_score_from_metrics(cv_r2, cv_pearson, cv_spearman, n_rows):
    r2_term = max(min((cv_r2 + 1.0) / 2.0, 1.0), 0.0)
    p_term  = max(min(((0.0 if pd.isna(cv_pearson) else cv_pearson) + 1.0) / 2.0, 1.0), 0.0)
    s_term  = max(min(((0.0 if pd.isna(cv_spearman) else cv_spearman) + 1.0) / 2.0, 1.0), 0.0)
    n_term  = max(min(np.log1p(n_rows) / np.log1p(500), 1.0), 0.0)
    return 0.40 * r2_term + 0.25 * p_term + 0.20 * s_term + 0.15 * n_term

def ic50_class_from_series(s):
    s = pd.Series(s, dtype=float)
    q1 = s.quantile(0.33)
    q2 = s.quantile(0.67)
    def classify(v):
        if v <= q1:
            return "LOW (better sensitivity)"
        elif v <= q2:
            return "MEDIUM"
        return "HIGH (worse sensitivity)"
    return classify

def normalize_label(x):
    return str(x).strip().lower()

def df_or_empty(rows, sort_by=None, ascending=False):
    df = pd.DataFrame(rows)
    if df.empty:
        return df
    if sort_by is not None:
        df = df.sort_values(sort_by, ascending=ascending).reset_index(drop=True)
    return df

class SharedPreprocessingService:
    def __init__(self, config: PipelineConfig):
        self.config = config

    def load_patient_expression(self, patient_expr_path: str, patient_sample: Optional[str] = None, patient_sample_index: int = 5):
        patient_df = pd.read_csv(patient_expr_path, sep="\t")
        patient_df.columns = [str(c).strip() for c in patient_df.columns]

        gene_col = pick_col(patient_df, ["GeneSymbol", "Hugo_Symbol", "gene", "GENE", "symbol"])
        if gene_col is None:
            raise ValueError("Could not identify the gene symbol column in the patient expression file.")

        expr_cols = [c for c in patient_df.columns if c != gene_col]
        patient_df[gene_col] = patient_df[gene_col].astype(str).str.strip().str.upper()
        patient_df = patient_df.drop_duplicates(subset=[gene_col]).copy()
        patient_mat = patient_df.set_index(gene_col)[expr_cols].apply(pd.to_numeric, errors="coerce")

        patient_numeric_cols = patient_mat.columns[patient_mat.notna().sum(axis=0) > 0].tolist()
        if not patient_numeric_cols:
            raise ValueError("No numeric patient sample columns were found in the expression matrix.")

        if patient_sample is None:
            chosen = patient_numeric_cols[patient_sample_index] if len(patient_numeric_cols) > patient_sample_index else patient_numeric_cols[0]
        else:
            if patient_sample not in patient_numeric_cols:
                raise ValueError(f"Requested patient sample '{patient_sample}' was not found.")
            chosen = patient_sample

        patient_vec = patient_mat[chosen].copy()
        mu = patient_mat.mean(axis=1)
        sd = patient_mat.std(axis=1).replace(0, np.nan)
        z = ((patient_vec - mu) / sd).replace([np.inf, -np.inf], np.nan).fillna(0.0)

        return {
            "patient_df": patient_df,
            "patient_mat": patient_mat,
            "patient_sample": chosen,
            "patient_vec": patient_vec,
            "patient_z": z,
            "available_samples": patient_numeric_cols,
        }

    def load_immune_map(self, immune_map_path: str, patient_gene_index: pd.Index):
        imap = pd.read_csv(immune_map_path, low_memory=False)
        imap.columns = [str(c).strip() for c in imap.columns]

        main_col = pick_col(imap, ["main_gene", "main", "gene", "gene_symbol"])
        indirect_col = pick_col(imap, ["indirectly_affected_gene", "indirect_gene", "indirect", "affected_gene"])
        if main_col is None or indirect_col is None:
            raise ValueError("IMMUNE_MAP_PATH must contain a main gene column and an indirect gene column.")

        main_genes = sorted(set(safe_upper_series(imap[main_col].dropna())))
        indirect_genes = sorted(set(safe_upper_series(imap[indirect_col].dropna())))
        signature_genes = sorted(set(main_genes) | set(indirect_genes))
        signature_genes_in_expr = [g for g in signature_genes if g in patient_gene_index]

        return {
            "immune_map": imap,
            "main_genes": main_genes,
            "indirect_genes": indirect_genes,
            "signature_genes": signature_genes,
            "signature_genes_in_expr": signature_genes_in_expr,
        }

    def load_dgidb_interactions(self, signature_genes_in_expr: List[str], dgidb_cache_path: str):
        if os.path.exists(dgidb_cache_path):
            interactions = pd.read_csv(dgidb_cache_path)
        else:
            if not DGIPY_AVAILABLE:
                raise ImportError(
                    "DGIdb cache not found and dgipy is not installed. "
                    "Provide a cached CSV or install dgipy."
                )
            parts = []
            for glist in chunk_list(signature_genes_in_expr, 50):
                try:
                    res = dgipy.get_interactions(terms=glist, search="genes")
                    if res is not None:
                        df_part = pd.DataFrame(res)
                        if not df_part.empty:
                            parts.append(df_part)
                except Exception as e:
                    print("DGIdb chunk failed:", e)
            interactions = pd.concat(parts, ignore_index=True) if parts else pd.DataFrame()
            if interactions.empty:
                raise ValueError("DGIdb returned no interaction rows.")
            interactions.to_csv(dgidb_cache_path, index=False)

        interactions.columns = [str(c).strip() for c in interactions.columns]
        drug_col = pick_col(interactions, ["drug_name", "drug", "name"])
        gene_col = pick_col(interactions, ["gene_name", "gene", "entrez_gene_symbol"])
        if drug_col is None or gene_col is None:
            raise ValueError("Could not identify drug and gene columns in DGIdb interactions.")

        return {
            "interactions": interactions,
            "drug_col": drug_col,
            "gene_col": gene_col,
        }

#kol drug b y target anhy genes
    def build_drug_target_scores(self, interactions: pd.DataFrame, drug_col: str, gene_col: str, main_genes: List[str], indirect_genes: List[str]):
        rows = []
        main_set = set(main_genes)
        indirect_set = set(indirect_genes)

        for drug_name, g in interactions.groupby(drug_col):
            genes = sorted(set(safe_upper_series(g[gene_col].dropna())))
            n_main = sum(x in main_set for x in genes)
            n_indirect = sum(x in indirect_set for x in genes)
            weighted_targets = 2 * n_main + 1 * n_indirect
            n_signature = sum((x in main_set) or (x in indirect_set) for x in genes)

            rows.append({
                "drug_name": str(drug_name).strip(),
                "n_interactions": len(g),
                "weighted_targets": weighted_targets,
                "n_main_targets": n_main,
                "n_indirect_targets": n_indirect,
                "n_unique_signature_genes": n_signature,
                "direct_targets": [x for x in genes if x in main_set],
                "indirect_targets": [x for x in genes if x in indirect_set],
            })

        return df_or_empty(rows, sort_by=["n_main_targets", "weighted_targets"], ascending=[False, False])

    def load_prism(self, prism_dose_response_path: str):
        prism = pd.read_csv(prism_dose_response_path, low_memory=False)
        prism.columns = [str(c).strip() for c in prism.columns]

        depmap_col = pick_col(prism, ["depmap_id", "DepMap_ID", "depmap"])
        name_col = pick_col(prism, ["drug_name", "name", "compound_name"])
        ic50_col = pick_col(prism, ["ic50_value", "ic50", "IC50"])
        if depmap_col is None or name_col is None or ic50_col is None:
            raise ValueError("PRISM file must contain depmap_id, drug_name/name, and ic50_value/ic50 columns.")

        pr = prism[[depmap_col, name_col, ic50_col]].copy()
        pr.columns = ["depmap_id", "drug_name", "ic50_value"]
        pr["drug_name"] = pr["drug_name"].astype(str).str.strip()
        pr["drug_norm"] = pr["drug_name"].map(norm_basic)
        pr["drug_norm_strong"] = pr["drug_name"].map(norm_strong)
        return pr

    def load_ccle(self, ccle_expr_path: str):
        ccle = pd.read_csv(ccle_expr_path, low_memory=False)
        ccle.columns = [str(c).strip() for c in ccle.columns]

        depmap_col = ccle.columns[0]
        ccle[depmap_col] = ccle[depmap_col].astype(str).str.strip().str.upper()
        ccle = ccle.drop_duplicates(subset=[depmap_col]).copy()

        rename_map = {c: normalize_ccle_gene(c) for c in ccle.columns[1:]}
        ccle = ccle.rename(columns=rename_map)

        ccle_mat = ccle.set_index(depmap_col)
        ccle_mat = ccle_mat.apply(pd.to_numeric, errors="coerce")
        return ccle_mat

#count lw drug trainable wala la
    def build_trainable_drug_table(self, drug_scores: pd.DataFrame, pr: pd.DataFrame):
        basic_to_canonical = (
            pr[["drug_name", "drug_norm"]]
            .drop_duplicates()
            .groupby("drug_norm")["drug_name"]
            .first()
            .to_dict()
        )
        strong_to_canonical = (
            pr[["drug_name", "drug_norm_strong"]]
            .drop_duplicates()
            .groupby("drug_norm_strong")["drug_name"]
            .first()
            .to_dict()
        )
#norm ll drug names
        def map_to_prism_name(name):
            b = norm_basic(name)
            s = norm_strong(name)
            if b in basic_to_canonical:
                return basic_to_canonical[b]
            if s in strong_to_canonical:
                return strong_to_canonical[s]
            return np.nan

        out = drug_scores.copy()
        out["prism_match"] = out["drug_name"].map(map_to_prism_name)
        out["prism_rows"] = out["prism_match"].map(
            pr.groupby("drug_name").size().to_dict()
        )
        out["is_trainable"] = out["prism_match"].notna()
        return out

class RankingService:
    def __init__(self, config: PipelineConfig, pr: pd.DataFrame, ccle_mat: pd.DataFrame, genes_for_model: List[str]):
        self.config = config
        self.pr = pr
        self.ccle_mat = ccle_mat
        self.genes_for_model = list(genes_for_model)
        self.model_registry = self.build_model_registry()


    def build_model_registry(self, seed=SEED):
        models = {
            "elasticnet": ElasticNet(alpha=0.1, l1_ratio=0.5, max_iter=10000, random_state=seed),
            "ridge": Ridge(alpha=1.0),
            "lasso": Lasso(alpha=0.01, max_iter=10000, random_state=seed),
            "random_forest": RandomForestRegressor(
                n_estimators=300, random_state=seed, n_jobs=-1, min_samples_leaf=2
            ),
            "extra_trees": ExtraTreesRegressor(
                n_estimators=300, random_state=seed, n_jobs=-1, min_samples_leaf=2
            ),
            "gradient_boosting": GradientBoostingRegressor(random_state=seed),
        }
        if XGBOOST_AVAILABLE:
            models["xgboost"] = XGBRegressor(
                n_estimators=300,
                max_depth=4,
                learning_rate=0.05,
                subsample=0.9,
                colsample_bytree=0.9,
                objective="reg:squarederror",
                random_state=seed,
                n_jobs=4,
            )
        return models

# l kol drug el genes bta3to m3 ic50 value
    def build_one_drug_dataset(self, prism_drug_name: str, min_rows: Optional[int] = None):
        min_rows = min_rows or self.config.min_rows
        dn = norm_basic(prism_drug_name)

        d = self.pr[self.pr["drug_norm"] == dn].copy()
        if len(d) == 0:
            d = self.pr[self.pr["drug_name"].astype(str).str.strip().str.lower() == dn].copy()
        if len(d) == 0:
            return None

        d = d[d["depmap_id"].isin(self.ccle_mat.index)].copy()
        d["ic50_value"] = pd.to_numeric(d["ic50_value"], errors="coerce")
        d = d.dropna(subset=["depmap_id", "ic50_value"]).copy()
        d = d.groupby("depmap_id", as_index=False)["ic50_value"].mean()

        if len(d) < min_rows:
            return None

        usable_genes = [g for g in self.genes_for_model if g in self.ccle_mat.columns]
        if len(usable_genes) == 0:
            return None

        X = self.ccle_mat.loc[d["depmap_id"], usable_genes].copy()
        X.index = d["depmap_id"].values
        X = X.apply(pd.to_numeric, errors="coerce")

        y_raw = pd.Series(d["ic50_value"].values, index=d["depmap_id"].values, name="ic50_value")
        y_raw = pd.to_numeric(y_raw, errors="coerce")

        keep_idx = y_raw.index[y_raw.notna() & np.isfinite(y_raw) & (y_raw > 0)]
        X = X.loc[keep_idx]
        y_raw = y_raw.loc[keep_idx]

        if len(y_raw) < min_rows:
            return None

        X = X.dropna(axis=1, how="all")
        if X.shape[1] == 0:
            return None

        X = X.fillna(X.median())
        nunique = X.nunique(dropna=False)
        keep_cols = nunique[nunique > 1].index.tolist()
        X = X[keep_cols]

        if X.shape[1] == 0:
            return None

        X = rowwise_z(X)
        y = pd.Series(np.log10(y_raw.astype(float) + 1e-8), index=y_raw.index, name="log10_ic50")

        return {
            "drug_name": prism_drug_name,
            "depmap_ids": list(X.index),
            "X": X,
            "y_log10_ic50": y,
            "y_ic50": y_raw,
            "feature_names": list(X.columns),
        }

    def evaluate_model_cv(self, X, y, model_name, model):
        X = pd.DataFrame(X).copy()
        y = pd.Series(y).copy()

        n_splits = min(self.config.cv_folds, len(y))
        if n_splits < 3:
            return None

        kf = KFold(n_splits=n_splits, shuffle=True, random_state=self.config.random_state)
        use_scaler = model_needs_scaler(model_name)

        oof_pred = pd.Series(index=y.index, dtype=float)
        fold_rows = []

        for fold, (tr_idx, va_idx) in enumerate(kf.split(X), start=1):
            Xtr, Xva = X.iloc[tr_idx], X.iloc[va_idx]
            ytr, yva = y.iloc[tr_idx], y.iloc[va_idx]

            scaler, Xtr2, Xva2 = make_scaler_and_transform(Xtr, Xva, use_scaler=use_scaler)

            m = clone(model)
            m.fit(Xtr2, ytr)
            pred = m.predict(Xva2)
            oof_pred.iloc[va_idx] = pred

            fold_rows.append({
                "fold": fold,
                "mae": mean_absolute_error(yva, pred),
                "rmse": float(np.sqrt(mean_squared_error(yva, pred))),
                "r2": r2_score(yva, pred),
                "pearson": safe_corr(yva, pred, "pearson"),
                "spearman": safe_corr(yva, pred, "spearman"),
            })

        fold_df = pd.DataFrame(fold_rows)
        return {
            "cv_mae": mean_absolute_error(y, oof_pred),
            "cv_rmse": float(np.sqrt(mean_squared_error(y, oof_pred))),
            "cv_r2": r2_score(y, oof_pred),
            "cv_pearson": safe_corr(y, oof_pred, "pearson"),
            "cv_spearman": safe_corr(y, oof_pred, "spearman"),
            "oof_pred": oof_pred,
            "fold_metrics": fold_df,
        }

    def fit_final_model(self, X, y, model_name, model):
        use_scaler = model_needs_scaler(model_name)
        scaler, X2, _ = make_scaler_and_transform(X, X, use_scaler=use_scaler)
        m = clone(model)
        m.fit(X2, y)
        return m, scaler

#training kol drug by trying every model
    def train_one_drug_ic50(self, prism_drug_name: str, min_rows: Optional[int] = None):
        ds = self.build_one_drug_dataset(prism_drug_name, min_rows=min_rows)
        if ds is None:
            return None

        X = ds["X"]
        y = ds["y_log10_ic50"]
        model_rows = []
        best = None
        best_fit = None

        for model_name, model in self.model_registry.items():
            try:
                metrics = self.evaluate_model_cv(X, y, model_name, model)
                if metrics is None:
                    continue

                final_model, final_scaler = self.fit_final_model(X, y, model_name, model)
                row = {
                    "model_name": model_name,
                    "cv_mae": metrics["cv_mae"],
                    "cv_rmse": metrics["cv_rmse"],
                    "cv_r2": metrics["cv_r2"],
                    "cv_pearson": metrics["cv_pearson"],
                    "cv_spearman": metrics["cv_spearman"],
                }
                model_rows.append(row)

                if (best is None) or (metrics["cv_r2"] > best["cv_r2"]):
                    best = {
                        "drug_name": prism_drug_name,
                        "best_model_name": model_name,
                        "n": len(y),
                        "X": X,
                        "y_log10_ic50": y,
                        "y_ic50": ds["y_ic50"],
                        "feature_names": list(X.columns),
                        "cv_mae": metrics["cv_mae"],
                        "cv_rmse": metrics["cv_rmse"],
                        "cv_r2": metrics["cv_r2"],
                        "cv_pearson": metrics["cv_pearson"],
                        "cv_spearman": metrics["cv_spearman"],
                        "oof_pred": metrics["oof_pred"],
                        "fold_metrics": metrics["fold_metrics"],
                        "depmap_ids": ds["depmap_ids"],
                    }
                    best_fit = {"model": final_model, "scaler": final_scaler}
            except Exception as e:
                model_rows.append({"model_name": model_name, "error": str(e)})

        if best is None:
            return None

        best["final_model"] = best_fit["model"]
        best["final_scaler"] = best_fit["scaler"]
        best["model_results"] = (
            pd.DataFrame(model_rows)
            .sort_values(["cv_r2", "cv_rmse"], ascending=[False, True], na_position="last")
            .reset_index(drop=True)
        )
        return best
# use trained drug model tto predict patient response
    def predict_patient_ic50(self, trained: Dict[str, Any], patient_vec: pd.Series):
        feat_names = trained["feature_names"]
        pv = pd.Series(patient_vec).copy()
        pv.index = pv.index.astype(str).str.upper()

        row = [pd.to_numeric(pv.get(gene, np.nan), errors="coerce") for gene in feat_names]
        Xp = pd.DataFrame([row], columns=feat_names)
        Xp = Xp.fillna(Xp.median(axis=0))
        Xp = rowwise_z(Xp)

        if trained["final_scaler"] is not None:
            Xp2 = trained["final_scaler"].transform(Xp)
        else:
            Xp2 = Xp.values

        pred_log10_ic50 = trained["final_model"].predict(Xp2)[0]
        pred_ic50 = 10 ** pred_log10_ic50
        return pred_log10_ic50, pred_ic50

#bt rank kol drugs
    def rank_candidates(self, trainable_df: pd.DataFrame, patient_vec: pd.Series, top_n: Optional[int] = None, candidate_drugs: Optional[List[str]] = None):
        top_n = top_n or self.config.top_n

        cands = trainable_df[trainable_df["is_trainable"]].copy()
        if candidate_drugs:
            wanted = {norm_basic(x) for x in candidate_drugs}
            cands = cands[cands["prism_match"].map(lambda x: norm_basic(x) if pd.notna(x) else x).isin(wanted)].copy()
        else:
            cands = cands.head(top_n).copy()

        results = []
        training_artifacts = {}

        for _, row in cands.iterrows():
            prism_name = str(row["prism_match"]).strip()
            trained = self.train_one_drug_ic50(prism_name, min_rows=self.config.min_rows)
            if trained is None:
                continue

            if trained["cv_r2"] < self.config.min_acceptable_r2:
                continue

            pred_log_ic50, pred_ic50 = self.predict_patient_ic50(trained, patient_vec)
            training_artifacts[prism_name] = trained

            results.append({
                "drug_name": prism_name,
                "best_model_name": trained["best_model_name"],
                "pred_log10_ic50": pred_log_ic50,
                "pred_ic50": pred_ic50,
                "n_train_rows": trained["n"],
                "cv_mae": trained["cv_mae"],
                "cv_rmse": trained["cv_rmse"],
                "cv_r2": trained["cv_r2"],
                "cv_pearson": trained["cv_pearson"],
                "cv_spearman": trained["cv_spearman"],
                "confidence_score_raw": confidence_score_from_metrics(
                    trained["cv_r2"], trained["cv_pearson"], trained["cv_spearman"], trained["n"]
                ),
                "model_results": trained["model_results"],
                "weighted_targets": row["weighted_targets"],
                "n_main_targets": row["n_main_targets"],
                "n_indirect_targets": row["n_indirect_targets"],
                "n_unique_signature_genes": row["n_unique_signature_genes"],
                "n_interactions": row["n_interactions"],
                "direct_targets": row["direct_targets"],
                "indirect_targets": row["indirect_targets"],
            })

        ranked_ic50 = pd.DataFrame(results)
        if ranked_ic50.empty:
            return {
                "ranked_ic50": ranked_ic50,
                "df_rank": pd.DataFrame(),
                "training_artifacts": training_artifacts,
            }

        ranked_ic50 = ranked_ic50.sort_values(
            ["n_main_targets", "weighted_targets", "pred_ic50"],
            ascending=[False, False, True]
        ).reset_index(drop=True)

        df_rank = ranked_ic50.copy()
        ic50_classifier = ic50_class_from_series(df_rank["pred_ic50"])
        df_rank["ic50_class"] = df_rank["pred_ic50"].apply(ic50_classifier)

        df_rank["score_targets"] = (
            0.6 * minmax01(df_rank["n_main_targets"]) +
            0.4 * minmax01(df_rank["weighted_targets"])
        )
        pear = df_rank["cv_pearson"].fillna(df_rank["cv_pearson"].min(skipna=True) if df_rank["cv_pearson"].notna().any() else 0.0)
        spear = df_rank["cv_spearman"].fillna(df_rank["cv_spearman"].min(skipna=True) if df_rank["cv_spearman"].notna().any() else 0.0)

        df_rank["score_model"] = (
            0.40 * minmax01(df_rank["cv_r2"]) +
            0.20 * (1.0 - minmax01(df_rank["cv_mae"])) +
            0.20 * (1.0 - minmax01(df_rank["cv_rmse"])) +
            0.10 * minmax01(pear) +
            0.10 * minmax01(spear)
        )
        df_rank["score_conf"] = minmax01(df_rank["confidence_score_raw"])
        df_rank["final_score"] = (
            self.config.w_targets * df_rank["score_targets"] +
            self.config.w_ic50    * df_rank["score_ic50"] if "score_ic50" in df_rank.columns else 0
        )
        df_rank["score_ic50"] = 1.0 - minmax01(df_rank["pred_ic50"])
        df_rank["final_score"] = (
            self.config.w_targets * df_rank["score_targets"] +
            self.config.w_ic50    * df_rank["score_ic50"] +
            self.config.w_model   * df_rank["score_model"] +
            self.config.w_conf    * df_rank["score_conf"]
        )

        def recommendation_from_score(x, s):
            if x >= s.quantile(0.67):
                return "Better"
            elif x >= s.quantile(0.33):
                return "Maybe"
            return "Worse"

        df_rank["recommendation"] = df_rank["final_score"].apply(lambda x: recommendation_from_score(x, df_rank["final_score"]))
        df_rank = df_rank.sort_values(
            ["final_score", "n_main_targets", "weighted_targets", "pred_ic50"],
            ascending=[False, False, False, True]
        ).reset_index(drop=True)

        return {
            "ranked_ic50": ranked_ic50,
            "df_rank": df_rank,
            "training_artifacts": training_artifacts,
        }
class DeepDenoisingAE(nn.Module):
    def __init__(self, input_dim, latent_dim=64):
        super().__init__()
        self.encoder = nn.Sequential(
            nn.Linear(input_dim, 512),
            nn.BatchNorm1d(512),
            nn.ReLU(),
            nn.Dropout(0.20),
            nn.Linear(512, 256),
            nn.BatchNorm1d(256),
            nn.ReLU(),
            nn.Linear(256, latent_dim),
        )
        self.decoder = nn.Sequential(
            nn.Linear(latent_dim, 256),
            nn.BatchNorm1d(256),
            nn.ReLU(),
            nn.Linear(256, 512),
            nn.BatchNorm1d(512),
            nn.ReLU(),
            nn.Linear(512, input_dim),
        )

    def forward(self, x):
        z = self.encoder(x)
        x_hat = self.decoder(z)
        return x_hat, z


class TwinService:
    def __init__(self, config: PipelineConfig, pathways: Dict[str, List[str]]):
        if not TORCH_AVAILABLE:
            raise ImportError("Torch is required for the digital twin section.")
        self.config = config
        self.pathways = {k: [normalize_gene_symbol(g) for g in v] for k, v in pathways.items()}

# load dataset and split
    def prepare_reference(self, twin_master_df_path: str, genes_for_model: List[str]):
        master_df = pd.read_csv(twin_master_df_path, low_memory=False)
        master_df.columns = [str(c).strip() for c in master_df.columns]

        if "Label" not in master_df.columns:
            raise ValueError("TWIN_MASTER_DF_PATH must contain a 'Label' column.")

        twin_gene_cols = [g for g in genes_for_model if g in master_df.columns]
        if len(twin_gene_cols) == 0:
            rename_map = {c: normalize_ccle_gene(c) for c in master_df.columns}
            master_df = master_df.rename(columns=rename_map)
            twin_gene_cols = [g for g in genes_for_model if g in master_df.columns]

        if len(twin_gene_cols) == 0:
            raise ValueError("No overlap between genes_for_model and the twin reference dataset.")

        healthy_values = {normalize_label(x) for x in self.config.healthy_label_values}
        master_df["Label_norm"] = master_df["Label"].map(normalize_label)
        healthy_mask = master_df["Label_norm"].isin(healthy_values)
        if healthy_mask.sum() == 0:
            raise ValueError("No healthy/control samples found in the twin dataset.")

        healthy_expr = master_df.loc[healthy_mask, twin_gene_cols].apply(pd.to_numeric, errors="coerce")
        healthy_expr = healthy_expr.fillna(healthy_expr.median())

        twin_scaler = RobustScaler()
        twin_scaler.fit(healthy_expr)

        X_master = master_df[twin_gene_cols].apply(pd.to_numeric, errors="coerce")
        X_master = X_master.fillna(healthy_expr.median())
        X_master_scaled = pd.DataFrame(
            twin_scaler.transform(X_master), columns=twin_gene_cols, index=master_df.index
        )
        healthy_scaled = X_master_scaled.loc[healthy_mask].copy()

        return {
            "master_df": master_df,
            "twin_gene_cols": twin_gene_cols,
            "healthy_mask": healthy_mask,
            "healthy_expr": healthy_expr,
            "twin_scaler": twin_scaler,
            "X_master_scaled": X_master_scaled,
            "healthy_scaled": healthy_scaled,
        }
#train autoencoder
    def train_twin_model(self, healthy_scaled: pd.DataFrame):
        healthy_tensor = torch.tensor(healthy_scaled.values, dtype=torch.float32, device=DEVICE)
        model = DeepDenoisingAE(len(healthy_scaled.columns), latent_dim=self.config.twin_latent_dim).to(DEVICE)

        optimizer = torch.optim.Adam(model.parameters(), lr=self.config.twin_lr)
        criterion = nn.MSELoss()
        scheduler = torch.optim.lr_scheduler.ReduceLROnPlateau(optimizer, "min", patience=10, factor=0.5)

        model.train()
        losses = []
        for epoch in range(self.config.twin_epochs):
            noise = 0.05 * torch.randn_like(healthy_tensor)
            optimizer.zero_grad()
            outputs, _ = model(healthy_tensor + noise)
            loss = criterion(outputs, healthy_tensor)
            loss.backward()
            optimizer.step()
            scheduler.step(loss.detach().cpu())
            losses.append(loss.item())

        return {
            "twin_model": model,
            "healthy_tensor": healthy_tensor,
            "losses": losses,
        }

#build person tensor to match with twin format
    def build_patient_tensor(self, patient_vec: pd.Series, twin_gene_cols: List[str], healthy_expr: pd.DataFrame, twin_scaler: RobustScaler):
        patient_aligned = pd.Series(
            {g: pd.to_numeric(patient_vec.get(g, np.nan), errors="coerce") for g in twin_gene_cols}
        )
        patient_aligned = patient_aligned.fillna(healthy_expr.median())
        patient_scaled = pd.Series(
            twin_scaler.transform(pd.DataFrame([patient_aligned.values], columns=twin_gene_cols))[0],
            index=twin_gene_cols,
            name=getattr(patient_vec, "name", "patient"),
        )
        patient_tensor = torch.tensor(patient_scaled.values.reshape(1, -1), dtype=torch.float32, device=DEVICE)
        return {
            "patient_aligned": patient_aligned,
            "patient_scaled": patient_scaled,
            "patient_tensor": patient_tensor,
        }

    def build_drug_target_map(self, interactions: pd.DataFrame, drug_col: str, gene_col: str):
        return (
            interactions[[drug_col, gene_col]]
            .dropna()
            .assign(
                _drug=lambda x: x[drug_col].astype(str).str.strip().str.lower(),
                _gene=lambda x: safe_upper_series(x[gene_col]),
            )
            .groupby("_drug")["_gene"]
            .apply(lambda s: sorted(set(s)))
            .to_dict()
        )

    def make_digital_twin(self, twin_gene_cols: List[str], healthy_tensor, drug_to_targets: Dict[str, List[str]]):
        return DigitalTwin(
            gene_cols=twin_gene_cols,
            healthy_tensor=healthy_tensor,
            drug_to_targets=drug_to_targets,
            pathways=self.pathways,
            config=self.config,
        )


class DigitalTwin:
    def __init__(self, gene_cols, healthy_tensor, drug_to_targets, pathways, config: PipelineConfig):
        self.config = config
        self.gene_cols = list(gene_cols)
        self.idx = {g: i for i, g in enumerate(self.gene_cols)}
        self.healthy_ref = healthy_tensor.mean(0, keepdim=True)
        self.drug_map = drug_to_targets
        self.pathways = pathways
#reconstruct patiant
    def calculate_risk(self, model, x):
        model.eval()
        with torch.no_grad():
            x_hat, _ = model(x)
            return torch.mean((x_hat - x) ** 2, dim=1)
# how many hits in the pathway(kam gene)
    def pathway_hits(self, genes):
        hits = {p: 0 for p in self.pathways}
        for g in genes:
            for p, p_genes in self.pathways.items():
                if g in p_genes:
                    hits[p] += 1
        return {p: c for p, c in hits.items() if c > 0}

    def gene_change(self, gene, before, after):
        i = self.idx[gene]

        b = before[0, i].item()
        a = after[0, i].item()
        h = self.healthy_ref[0, i].item()

        # distance to healthy BEFORE and AFTER
        dist_before = abs(b - h)
        dist_after = abs(a - h)

        if dist_after < dist_before:
            direction = "✅ Improved (toward healthy)"
            score = dist_before - dist_after
        elif dist_after > dist_before:
            direction = "❌ Worsened (away from healthy)"
            score = dist_after - dist_before
        else:
            direction = "➖ No change"
            score = 0.0

        return {
            "gene": gene,
            "before": b,
            "after": a,
            "healthy": h,
            "direction": direction,
            "improvement_score": score
        }

#map drugs to gene
    def _resolve_targets(self, drug_name):
        dn = norm_basic(drug_name)
        sn = norm_strong(drug_name)
        if dn in self.drug_map:
            return self.drug_map[dn]
        for k in self.drug_map:
            if norm_strong(k) == sn:
                return self.drug_map[k]
        return []

    def _simulate_single(self, patient, valid_targets, alpha):
        after = patient.clone()
        for g in valid_targets:
            idx = self.idx[g]
            after[0, idx] = after[0, idx] + alpha * (self.healthy_ref[0, idx] - after[0, idx])
        return after

    def _simulate_pair(self, patient, valid_targets_a, valid_targets_b, alpha_a, alpha_b):
        after = patient.clone()
        for g in valid_targets_a:
            idx = self.idx[g]
            after[0, idx] = after[0, idx] + alpha_a * (self.healthy_ref[0, idx] - after[0, idx])
        for g in valid_targets_b:
            idx = self.idx[g]
            after[0, idx] = after[0, idx] + min(alpha_b + self.config.sim_pair_extra_alpha, 0.85) * (
                self.healthy_ref[0, idx] - after[0, idx]
            )
        return after
    def simulate_single(self, patient, valid_targets, alpha):
        return self._simulate_single(patient, valid_targets, alpha)

    def simulate_pair(self, patient, valid_targets_a, valid_targets_b, alpha_a, alpha_b):
        return self._simulate_pair(
            patient,
            valid_targets_a,
            valid_targets_b,
            alpha_a,
            alpha_b
        )
    def evaluate_single_drugs(self, model, patient, rank_df, top_k=None):
        top_k = top_k or self.config.sim_top_k_drugs
        baseline = self.calculate_risk(model, patient)
        base_value = baseline.item()
        subset = rank_df.head(top_k).copy()
        results = []

        for _, row in subset.iterrows():
            drug_name = str(row["drug_name"]).strip()
            alpha = self.config.sim_base_alpha + 0.20 * float(row["score_conf"]) if "score_conf" in row else self.config.sim_base_alpha

            targets = self._resolve_targets(drug_name)
            valid = [t for t in targets if t in self.idx]
            if not valid:
                continue

            after = self._simulate_single(patient, valid, alpha=alpha)
            pathway_shift = self.compute_pathway_shift(
                patient,
                after
            )

            pathway_improvement_score = pathway_shift[
                "improvement"
            ].mean()
            after_risk = self.calculate_risk(model, after).item()
            reduction_pct = ((base_value - after_risk) / base_value * 100.0) if base_value != 0 else 0.0
            pathways = self.pathway_hits(valid)
            top_pathway = max(pathways, key=lambda k: pathways[k]) if pathways else "None"

            results.append({
                "drug_name": drug_name,
                "rank_final_score": float(row["final_score"]),
                "rank_confidence": float(row["score_conf"]) if "score_conf" in row else np.nan,
                "baseline_risk": base_value,
                "after_risk": after_risk,
                "risk_reduction_pct": reduction_pct,
                "n_valid_targets_in_twin": len(valid),
                "pathway_hits": pathways,
                "top_pathway": top_pathway,
                "gene_changes": [self.gene_change(g, patient, after) for g in valid], # changed to gene_change
                "pathway_shift": pathway_shift,
                "pathway_improvement_score": pathway_improvement_score,
            })

        return df_or_empty(results, sort_by=["risk_reduction_pct", "n_valid_targets_in_twin"], ascending=[False, False])

    def evaluate_pairs(self, model, patient, rank_df, top_k=None):
        top_k = top_k or self.config.sim_top_k_drugs
        baseline = self.calculate_risk(model, patient)
        base_value = baseline.item()

        subset = rank_df.head(top_k).copy()
        rows = []
        for (_, a), (_, b) in combinations(subset.iterrows(), 2):
            drug_a = str(a["drug_name"]).strip()
            drug_b = str(b["drug_name"]).strip()

            targets_a = [t for t in self._resolve_targets(drug_a) if t in self.idx]
            targets_b = [t for t in self._resolve_targets(drug_b) if t in self.idx]
            if (not targets_a) and (not targets_b):
                continue

            alpha_a = self.config.sim_base_alpha + 0.20 * float(a["score_conf"]) if "score_conf" in a else self.config.sim_base_alpha
            alpha_b = self.config.sim_base_alpha + 0.20 * float(b["score_conf"]) if "score_conf" in b else self.config.sim_base_alpha

            after = self._simulate_pair(patient, targets_a, targets_b, alpha_a, alpha_b)
            pathway_shift = self.compute_pathway_shift(
                patient,
                after
            )

            pathway_improvement_score = pathway_shift[
                "improvement"
            ].mean()
            after_risk = self.calculate_risk(model, after).item()
            reduction_pct = ((base_value - after_risk) / base_value * 100.0) if base_value != 0 else 0.0

            combined_targets = sorted(set(targets_a + targets_b))
            pathways = self.pathway_hits(combined_targets)
            top_pathway = max(pathways, key=lambda k: pathways[k]) if pathways else "None"

            rows.append({
                "combo_name": f"{drug_a} + {drug_b}",
                "drug_a": drug_a,
                "drug_b": drug_b,
                "baseline_risk": base_value,
                "after_risk": after_risk,
                "risk_reduction_pct": reduction_pct,
                "n_valid_targets_in_twin": len(combined_targets),
                "pathway_hits": pathways,
                "top_pathway": top_pathway,
                "gene_changes": [
                  self.gene_change(g, patient, after)
                  for g in combined_targets
              ],
              "pathway_shift": pathway_shift,
              "pathway_improvement_score": pathway_improvement_score,
            })

        return df_or_empty(rows, sort_by=["risk_reduction_pct", "n_valid_targets_in_twin"], ascending=[False, False])
    def compute_pathway_shift(self, before, after):

      rows = []

      for pathway, genes in self.pathways.items():

          valid = [
              g for g in genes
              if g in self.idx
          ]

          if len(valid) == 0:
              continue

          before_vals = []
          after_vals = []
          healthy_vals = []

          for g in valid:
              idx = self.idx[g]

              before_vals.append(
                  before[0, idx].item()
              )

              after_vals.append(
                  after[0, idx].item()
              )

              healthy_vals.append(
                  self.healthy_ref[0, idx].item()
              )

          before_score = np.mean(before_vals)
          after_score = np.mean(after_vals)
          healthy_score = np.mean(healthy_vals)

          dist_before = abs(before_score - healthy_score)
          dist_after = abs(after_score - healthy_score)

          improvement = dist_before - dist_after

          rows.append({
              "pathway": pathway,
              "before_score": before_score,
              "after_score": after_score,
              "healthy_score": healthy_score,
              "improvement": improvement
          })

      return pd.DataFrame(rows)
class FusionService:
    def __init__(self, config: PipelineConfig):
        self.config = config

    def fuse_single(self, df_rank: pd.DataFrame, twin_single: pd.DataFrame):
        if df_rank.empty:
            return pd.DataFrame()

        if twin_single.empty:
            fused_single = df_rank.copy()
            fused_single["risk_reduction_pct"] = np.nan
            fused_single["pathway_coverage_score"] = np.nan
            fused_single["score_pathway_improvement"] = minmax01(
                fused_single["pathway_improvement_score"].fillna(0)
            )
            # Initialize score_twin to 0.0 when twin_single is empty
            fused_single["score_twin"] = 0.0

            fused_single["combined_score"] = (
                self.config.fusion_w_rank * fused_single["final_score"] +
                self.config.fusion_w_twin * fused_single["score_twin"] +
                self.config.fusion_w_conf * fused_single["score_conf"] +
                self.config.fusion_w_path * fused_single["score_pathway_improvement"]
            )
            return fused_single

        twin_single_merge = twin_single.copy()
        # Ensure 'drug_name_norm' is created before it's used in the merge
        twin_single_merge["drug_name_norm"] = twin_single_merge["drug_name"].map(norm_basic)

        df_rank_merge = df_rank.copy()
        df_rank_merge["drug_name_norm"] = df_rank_merge["drug_name"].map(norm_basic)

        fused_single = df_rank_merge.merge(
            # Include 'pathway_improvement_score' in the merge
            twin_single_merge[["drug_name_norm", "risk_reduction_pct", "n_valid_targets_in_twin", "top_pathway", "pathway_improvement_score"]],
            on="drug_name_norm",
            how="left",
        ).copy()

        fallback_rr = fused_single["risk_reduction_pct"].min(skipna=True) if fused_single["risk_reduction_pct"].notna().any() else 0.0
        fused_single["score_twin"] = minmax01(fused_single["risk_reduction_pct"].fillna(fallback_rr))
        fused_single["pathway_coverage_score"] = minmax01(fused_single["n_valid_targets_in_twin"].fillna(0))
        # Calculate score_pathway_improvement for the merged dataframe
        fused_single["score_pathway_improvement"] = minmax01(fused_single["pathway_improvement_score"].fillna(0))

        fused_single["combined_score"] = (
            self.config.fusion_w_rank * fused_single["final_score"] +
            self.config.fusion_w_twin * fused_single["score_twin"] +
            self.config.fusion_w_conf * fused_single["score_conf"] +
            self.config.fusion_w_path * fused_single["score_pathway_improvement"]
        )
        fused_single = fused_single.sort_values(
            ["combined_score", "final_score", "risk_reduction_pct"],
            ascending=[False, False, False]
        ).reset_index(drop=True)
        return fused_single

    def rank_pairs(self, twin_pairs: pd.DataFrame):
        if twin_pairs.empty:
            return pd.DataFrame()

        combo_rank = twin_pairs.copy()
        combo_rank["score_twin"] = minmax01(combo_rank["risk_reduction_pct"])
        combo_rank["score_path"] = minmax01(combo_rank["n_valid_targets_in_twin"])
        combo_rank["combo_score"] = 0.75 * combo_rank["score_twin"] + 0.25 * combo_rank["score_path"]
        combo_rank = combo_rank.sort_values(
            ["combo_score", "risk_reduction_pct", "n_valid_targets_in_twin"],
            ascending=[False, False, False]
        ).reset_index(drop=True)
        return combo_rank
    

def run_therapy_pipeline(
    config: PipelineConfig,
    patient_expr_path: Optional[str] = None,
    patient_sample: Optional[str] = None,
    patient_sample_index: int = 5,
    candidate_drugs: Optional[List[str]] = None,
):
    shared = SharedPreprocessingService(config)

    patient_bundle = shared.load_patient_expression(
        patient_expr_path=patient_expr_path or config.patient_expr_path,
        patient_sample=patient_sample,
        patient_sample_index=patient_sample_index,
    )
    patient_vec = patient_bundle["patient_vec"]
   
    immune_bundle = shared.load_immune_map(
        immune_map_path=config.immune_map_path,
        patient_gene_index=patient_bundle["patient_mat"].index,
    )
    signature_genes_in_expr = immune_bundle["signature_genes_in_expr"]

    dgidb_bundle = shared.load_dgidb_interactions(
        signature_genes_in_expr=signature_genes_in_expr,
        dgidb_cache_path=config.dgidb_cache_path,
    )
    interactions = dgidb_bundle["interactions"]
    drug_col = dgidb_bundle["drug_col"]
    gene_col = dgidb_bundle["gene_col"]

    drug_scores = shared.build_drug_target_scores(
        interactions=interactions,
        drug_col=drug_col,
        gene_col=gene_col,
        main_genes=immune_bundle["main_genes"],
        indirect_genes=immune_bundle["indirect_genes"],
    )

    pr = shared.load_prism(config.prism_dose_response_path)
    ccle_mat = shared.load_ccle(config.ccle_expr_path)
    baseline_pathways = compute_pathway_activity(
    patient_vec,
    PATHWAYS,
    ccle_reference=ccle_mat
)

    genes_for_model = [g for g in signature_genes_in_expr if g in ccle_mat.columns]

    trainable = shared.build_trainable_drug_table(drug_scores=drug_scores, pr=pr)

    ranking_service = RankingService(
        config=config,
        pr=pr,
        ccle_mat=ccle_mat,
        genes_for_model=genes_for_model,
    )
    ranking_bundle = ranking_service.rank_candidates(
        trainable_df=trainable,
        patient_vec=patient_vec,
        top_n=config.top_n,
        candidate_drugs=candidate_drugs,
    )

    df_rank = ranking_bundle["df_rank"]

    twin_service = TwinService(config=config, pathways=PATHWAYS)
    twin_ref = twin_service.prepare_reference(
        twin_master_df_path=config.twin_master_df_path,
        genes_for_model=genes_for_model,
    )
    twin_fit = twin_service.train_twin_model(twin_ref["healthy_scaled"])
    patient_twin = twin_service.build_patient_tensor(
        patient_vec=patient_vec,
        twin_gene_cols=twin_ref["twin_gene_cols"],
        healthy_expr=twin_ref["healthy_expr"],
        twin_scaler=twin_ref["twin_scaler"],
    )
    drug_to_targets = twin_service.build_drug_target_map(
        interactions=interactions,
        drug_col=drug_col,
        gene_col=gene_col,
    )
    twin = twin_service.make_digital_twin(
        twin_gene_cols=twin_ref["twin_gene_cols"],
        healthy_tensor=twin_fit["healthy_tensor"],
        drug_to_targets=drug_to_targets,
    )
    twin_single = twin.evaluate_single_drugs(
        model=twin_fit["twin_model"],
        patient=patient_twin["patient_tensor"],
        rank_df=df_rank,
        top_k=min(config.sim_top_k_drugs, len(df_rank)) if not df_rank.empty else 0,
    )
    twin_pairs = twin.evaluate_pairs(
        model=twin_fit["twin_model"],
        patient=patient_twin["patient_tensor"],
        rank_df=df_rank,
        top_k=min(config.sim_top_k_drugs, len(df_rank)) if not df_rank.empty else 0,
    )

    fusion_service = FusionService(config)
    fused_single = fusion_service.fuse_single(df_rank=df_rank, twin_single=twin_single)
    combo_rank = fusion_service.rank_pairs(twin_pairs=twin_pairs)

    return {
        "config": asdict(config),
        "patient_bundle": patient_bundle,
        "immune_bundle": immune_bundle,
        "drug_scores": drug_scores,
        "trainable": trainable,
        "genes_for_model": genes_for_model,
        "ranking_bundle": ranking_bundle,
        "twin_reference": twin_ref,
        "twin_fit": twin_fit,
        "patient_twin": patient_twin,
        "twin_single": twin_single,
        "twin_pairs": twin_pairs,
        "fused_single": fused_single,
        "combo_rank": combo_rank,
        "baseline_pathways": baseline_pathways,
    }

# ============================================================
# EXPLAINABLE AI (BIOLOGICAL + SHAP VERSION)
# ============================================================

import shap
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

print("\n" + "="*60)
print("EXPLAINABLE AI (BIOLOGICAL + SHAP)")
print("="*60)

