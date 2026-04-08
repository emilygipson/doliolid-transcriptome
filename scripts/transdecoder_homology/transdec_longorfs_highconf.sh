#!/bin/bash
#SBATCH --job-name=transdecoder_longorfs
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=12:00:00
#SBATCH --output=longorfs_%j.out
#SBATCH --error=longorfs_%j.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=eeg37520@uga.edu

module purge
module load GCC/12.3.0
module load TransDecoder/5.7.1-GCC-12.3.0

TRANSCRIPTOME="/scratch/eeg37520/Sept2025_Trinity/9.22.25_TranscriptAssembly_downstream/clean_transcriptome_assembly.fasta"
CPU=16
OUTDIR="/scratch/eeg37520/transdecoder_homology/final_ref"

mkdir -p "$OUTDIR"

TransDecoder.LongOrfs \
    -t "$TRANSCRIPTOME" \
    --gene_trans_map /dev/null \
    --output_dir "$OUTDIR" \
    --complete_orfs_only

