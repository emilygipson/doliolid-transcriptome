#!/bin/bash
#SBATCH --job-name=filter_clustered_ref
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=12:00:00
#SBATCH --output=filter_clustered_ref_%j.out
#SBATCH --error=filter_clustered_ref_%j.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=eeg37520@uga.edu

module purge
module load GCC/13.3.0
module load CD-HIT/4.8.1-GCC-12.3.0

# -----------------------------
# Variables
# -----------------------------
OUTDIR="/scratch/eeg37520/transdecoder_homology"
PROT="$OUTDIR/both_supported.proteins.pep"   # proteins with Pfam AND BLAST hits
CDS="$OUTDIR/both_supported.cds"             # matching CDS FASTA
FINAL_PROT="$OUTDIR/final_ref.proteins.pep"
FINAL_CDS="$OUTDIR/final_ref.cds"
SUMMARY="$OUTDIR/filter_summary.txt"

mkdir -p "$OUTDIR"

# -----------------------------
# Summary BEFORE clustering
# -----------------------------
echo "Summary BEFORE clustering:" > "$SUMMARY"
echo -n "Total high-confidence proteins: " >> "$SUMMARY"
grep -c "^>" "$PROT" >> "$SUMMARY"

# -----------------------------
# Cluster proteins with CD-HIT (remove redundancy)
# -----------------------------
echo "Clustering proteins to remove redundancy..."
cd-hit -i "$PROT" -o "$FINAL_PROT" -c 0.95 -n 5 -T 16 -M 0

# -----------------------------
# Extract matching CDS for clustered proteins
# -----------------------------
echo "Extracting CDS for clustered proteins..."
python3 - <<EOF
from Bio import SeqIO

prot_ids = set([rec.id for rec in SeqIO.parse("$FINAL_PROT", "fasta")])
with open("$CDS") as cds_in, open("$FINAL_CDS", "w") as cds_out:
    for rec in SeqIO.parse(cds_in, "fasta"):
        if rec.id in prot_ids:
            SeqIO.write(rec, cds_out, "fasta")
EOF

# -----------------------------
# Summary AFTER clustering
# -----------------------------
echo "" >> "$SUMMARY"
echo "Summary AFTER clustering:" >> "$SUMMARY"
echo -n "Clustered proteins: " >> "$SUMMARY"
grep -c "^>" "$FINAL_PROT" >> "$SUMMARY"
echo -n "Matching CDS: " >> "$SUMMARY"
grep -c "^>" "$FINAL_CDS" >> "$SUMMARY"

echo "Filter and clustering step complete. Summary written to $SUMMARY"
