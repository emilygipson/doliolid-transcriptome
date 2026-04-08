#!/bin/bash
#SBATCH --job-name=cdhit_refprot
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=12:00:00
#SBATCH --output=cdhit_refprot_%j.out
#SBATCH --error=cdhit_refprot_%j.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=eeg37520@uga.edu

module purge
module load GCC/13.3.0
module load CD-HIT/4.8.1-GCC-12.3.0

# -----------------------------
# Variables
# -----------------------------
INPUT="/scratch/eeg37520/transdecoder_homology/final_ref.proteins.pep"
OUTDIR="/scratch/eeg37520/transdecoder_homology/cdhit"
OUTPUT="$OUTDIR/final_ref.proteins.nr95.pep"
CLUSTER_ID=0.95      # Sequence identity threshold
CPU=16               # Number of threads

mkdir -p "$OUTDIR"

echo "Starting CD-HIT at $(date)..."
cd-hit -i "$INPUT" \
       -o "$OUTPUT" \
       -c $CLUSTER_ID \
       -n 5 \
       -T $CPU \
       -M 0 \
       -d 0 \
       -g 1

STATUS=$?
if [[ $STATUS -ne 0 ]]; then
    echo "[ERROR] CD-HIT failed."
    exit 1
fi

echo "CD-HIT finished at $(date)"
echo "Non-redundant protein FASTA: $OUTPUT"
