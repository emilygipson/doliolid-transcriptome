#!/bin/bash
#SBATCH --job-name=transdecoder_cds
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=12:00:00
#SBATCH --output=transdecoder_cds_%j.out
#SBATCH --error=transdecoder_cds_%j.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=eeg37520@uga.edu

module purge
module load GCC/12.3.0
module load TransDecoder/5.7.1-GCC-12.3.0

# -----------------------------
# Variables
# -----------------------------
TRANSCRIPTOME="/scratch/eeg37520/Sept2025_Trinity/9.22.25_TranscriptAssembly_downstream/clean_transcriptome_assembly.fasta"

PFAM_DOM="/scratch/eeg37520/transdecoder_homology/pfam_all.domtblout"
BLASTP_OUT="/scratch/eeg37520/transdecoder_homology/all_chunks.blastp.out"
OUTDIR="/scratch/eeg37520/transdecoder_homology/final_ref"
CPU=16

mkdir -p "$OUTDIR"

echo "Starting TransDecoder.Predict at $(date)..."
TransDecoder.Predict \
    -t "$TRANSCRIPTOME" \
    --retain_pfam_hits "/scratch/eeg37520/transdecoder_homology/pfam_all.domtblout" \
    --retain_blastp_hits "/scratch/eeg37520/transdecoder_homology/all_chunks.blastp.out" \
    --cpu "$CPU" \
    --output_dir "$OUTDIR"

STATUS=$?
if [[ $STATUS -ne 0 ]]; then
    echo "[ERROR] TransDecoder.Predict failed."
    exit 1
fi

echo "TransDecoder.Predict finished at $(date)"
echo "Predicted CDS: $OUTDIR/*.transdecoder.cds"
echo "Predicted proteins: $OUTDIR/*.transdecoder.pep"
