import pandas as pd
from django.db import connection


def load_prism_from_db():
    query = """
        select depmap_id, drug_name, ic50_value
        from twin_prism
    """
    df = pd.read_sql(query, connection)
    df["drug_norm"] = df["drug_name"].astype(str).str.strip().str.lower()
    df["drug_norm_strong"] = df["drug_norm"]
    return df


def load_ccle_from_db():
    query = """
        select depmap_id, gene_symbol, expression_value
        from twin_ccle_expression
    """
    long_df = pd.read_sql(query, connection)

    wide_df = long_df.pivot_table(
        index="depmap_id",
        columns="gene_symbol",
        values="expression_value",
        aggfunc="mean"
    )

    wide_df.index = wide_df.index.astype(str).str.upper()
    wide_df.columns = wide_df.columns.astype(str).str.upper()

    return wide_df


def load_master_df_from_db():
    query = """
        select sample_id, label, batch, gene_symbol, expression_value
        from twin_master_expression
    """
    long_df = pd.read_sql(query, connection)

    wide_df = long_df.pivot_table(
        index=["sample_id", "label", "batch"],
        columns="gene_symbol",
        values="expression_value",
        aggfunc="mean"
    ).reset_index()

    wide_df = wide_df.rename(columns={
        "label": "Label",
        "sample_id": "SampleID",
        "batch": "Batch"
    })

    wide_df.columns = [str(c).strip().upper() if c not in ["Label", "SampleID", "Batch"] else c for c in wide_df.columns]

    return wide_df


def load_dgidb_from_db():
    query = """
        select drug_name, gene_symbol, interaction_type
        from twin_dgidb_interactions
    """
    return pd.read_sql(query, connection)


def load_immune_map_from_db():
    query = """
        select main_gene, related_gene, pathway_name, relation_type, weight
        from twin_immune_map
    """
    return pd.read_sql(query, connection)