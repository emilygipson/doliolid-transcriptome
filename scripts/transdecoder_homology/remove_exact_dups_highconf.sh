#!/bin/bash
#SBATCH --job-name=rmdup_high_conf
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=01:00:00
#SBATCH --output=rmdup_high_conf_%j.out
#SBATCH --error=rmdup_high_conf_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=eeg37520@uga.edu

# ---------------------------------------------
# Step 1: Remove exact duplicate sequences
# ---------------------------------------------

module purge
module load SeqKit/2.9.0

# Input files
PROTEIN_FASTA="/scratch/eeg37520/transdecoder_homology/high_conf_debug/both_supported.proteins.pep"
CDS_FASTA="/scratch/eeg37520/transdecoder_homology/high_conf_debug/both_supported.cds"

# Output directory
OUTDIR="/scratch/eeg37520/transdecoder_homology/high_conf_debug/rmdup"
mkdir -p "$OUTDIR"

# Logging
LOG="$OUTDIR/rmdup_summary.txt"
echo "Exact duplicate removal summary" > "$LOG"
echo "---------------------------------" >> "$LOG"
echo "Date: $(date)" >> "$LOG"

# Protein sequences
echo "Processing protein FASTA..." | tee -a "$LOG"
orig_prots=$(grep -c '^>' "$PROTEIN_FASTA")
echo "Original protein sequences: $orig_prots" | tee -a "$LOG"

seqkit rmdup -s -i "$PROTEIN_FASTA" -o "$OUTDIR/both_supported.proteins.rmdup.pep"

new_prots=$(grep -c '^>' "$OUTDIR/both_supported.proteins.rmdup.pep")
echo "Protein sequences after exact duplicate removal: $new_prots" | tee -a "$LOG"
echo "" >> "$LOG"

# CDS sequences
echo "Processing CDS FASTA..." | tee -a "$LOG"
orig_cds=$(grep -c '^>' "$CDS_FASTA")
echo "Original CDS sequences: $orig_cds" | tee -a "$LOG"

seqkit rmdup -s -i "$CDS_FASTA" -o "$OUTDIR/both_supported.cds.rmdup"

new_cds=$(grep -c '^>' "$OUTDIR/both_supported.cds.rmdup")
echo "CDS sequences after exact duplicate removal: $new_cds" | tee -a "$LOG"

echo "---------------------------------" >> "$LOG"
echo "Step 1 complete." | tee -a "$LOG"
echo "Outputs:"
echo "  Proteins: $OUTDIR/both_supported.proteins.rmdup.pep"
echo "  CDS:      $OUTDIR/both_supported.cds.rmdup"
