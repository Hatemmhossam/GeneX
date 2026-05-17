import os
import django
import csv

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "backend.settings")
django.setup()

from api.models import DrugInteraction

csv_file = "db_drug_interactions.csv"

with open(csv_file, newline='', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    batch = []
    for row in reader:
        batch.append(
            DrugInteraction(
                drug_1=row["Drug 1"].strip(),
                drug_2=row["Drug 2"].strip(),
                interaction_description=row["Interaction Description"].strip(),
            )
        )

        if len(batch) >= 1000:
            DrugInteraction.objects.bulk_create(batch, ignore_conflicts=True)
            batch = []

    if batch:
        DrugInteraction.objects.bulk_create(batch, ignore_conflicts=True)

print("Import finished.")