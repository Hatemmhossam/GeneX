
import torch
import torch.nn as nn

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

class DigitalTwin:
    def __init__(self, gene_cols, healthy_tensor, drug_to_targets, config):
        self.config = config
        self.gene_cols = list(gene_cols)
        self.idx = {g: i for i, g in enumerate(self.gene_cols)}
        self.healthy_ref = healthy_tensor.mean(0, keepdim=True)
        self.drug_map = drug_to_targets

    def calculate_risk(self, model, x):
        model.eval()
        with torch.no_grad():
            x_hat, _ = model(x)
            return torch.mean((x_hat - x) ** 2, dim=1)

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

    def resolve_targets(self, drug_name):
        dn = norm_basic(drug_name)
        sn = norm_strong(drug_name)
        if dn in self.drug_map:
            return self.drug_map[dn]
        for k in self.drug_map:
            if norm_strong(k) == sn:
                return self.drug_map[k]
        return []

    def simulate_single(self, patient, valid_targets, alpha):
        after = patient.clone()
        for g in valid_targets:
            idx = self.idx[g]
            after[0, idx] = after[0, idx] + alpha * (self.healthy_ref[0, idx] - after[0, idx])
        return after

    def simulate_pair(self, patient, valid_targets_a, valid_targets_b, alpha_a, alpha_b):
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