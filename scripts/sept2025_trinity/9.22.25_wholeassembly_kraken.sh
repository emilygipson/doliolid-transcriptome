#!/bin/bash
#SBATCH --job-name=kraken2_transcriptomev2
#SBATCH --partition=highmem_p
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=400gb
#SBATCH --time=48:00:00
#SBATCH --output=kraken2_transcriptome.%j.out
#SBATCH --error=kraken2_transcriptome.%j.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=eeg37520@uga.edu

cd "$SLURM_SUBMIT_DIR"

module load Kraken2/2.1.3-gompi-2023a

ASSEMBLY=/scratch/eeg37520/Sept2025_Trinity/9.22.25_TranscriptAssembly_downstream/4samp_trinity_out.fasta
DB=/db/kraken2/20250814/core_nt
OUTPUT_DIR=/scratch/eeg37520/Sept2025_Trinity/9.22.25_TranscriptAssembly_downstream/kraken_out
mkdir -p "$OUTPUT_DIR"

BASENAME=$(basename "$ASSEMBLY" .fasta)

# One-line Kraken2 call (works on older versions)
kraken2 --db "$DB" \
  --threads "$SLURM_CPUS_PER_TASK" \
  --output "$OUTPUT_DIR/${BASENAME}_kraken_full_out_classifications.txt" \
  --unclassified-out "$OUTPUT_DIR/${BASENAME}_unclassified.fa" \
  --classified-out "$OUTPUT_DIR/${BASENAME}_classified.fa" \
  --report "$OUTPUT_DIR/${BASENAME}_kraken_full.report.txt" \
  "$ASSEMBLY"
