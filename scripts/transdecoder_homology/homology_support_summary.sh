#!/bin/bash
#SBATCH --job-name=homology_summary
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=01:00:00
#SBATCH --output=homology_summary_%j.out
#SBATCH --error=homology_summary_%j.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=eeg37520@uga.edu

# Paths to your files
PFAM_DOM="/scratch/eeg37520/transdecoder_homology/pfam_all.domtblout"
BLAST_OUT="/scratch/eeg37520/transdecoder_homology/all_chunks.blastp.out"
PEP="/scratch/eeg37520/Sept2025_Trinity/9.22.25_TranscriptAssembly_downstream/clean_transcriptome_assembly.fasta.transdecoder_dir/longest_orfs.pep"
OUTDIR="/scratch/eeg37520/transdecoder_homology"

mkdir -p "$OUTDIR"

cd "$OUTDIR"

echo "Extracting IDs from Pfam domtblout..."
grep -v '^#' "$PFAM_DOM" \
  | awk '{sub(/\.p[0-9]+$/,"",$4); print $4}' \
  | sort -u > pfam.ids

echo "Extracting IDs from BLAST output..."
awk '{sub(/\.p[0-9]+$/,"",$1); print $1}' "$BLAST_OUT" \
  | sort -u > blast.ids

echo "Counting total predicted ORFs..."
total_orfs=$(grep -c '^>' "$PEP")

pfam_count=$(wc -l < pfam.ids)
blast_count=$(wc -l < blast.ids)
both_count=$(comm -12 pfam.ids blast.ids | wc -l)

{
  echo -e "Metric\tCount"
  echo -e "Total predicted ORFs\t$total_orfs"
  echo -e "ORFs with Pfam hit\t$pfam_count"
  echo -e "ORFs with BLAST hit\t$blast_count"
  echo -e "ORFs with Pfam AND BLAST hit\t$both_count"
} > homology_summary.txt

echo "Summary written to $OUTDIR/homology_summary.txt"
