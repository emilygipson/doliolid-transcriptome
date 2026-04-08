#!/bin/bash
#SBATCH --job-name=extract_high_conf
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1          # seqtk is single-threaded
#SBATCH --mem=8G
#SBATCH --time=02:00:00
#SBATCH --output=extract_high_conf_%j.out
#SBATCH --error=extract_high_conf_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=eeg37520@uga.edu

# ------------------------------
# Purpose:
#   Extract high-confidence protein (pep) and CDS sequences
#   from TransDecoder output, using the list of ORF IDs that
#   had both BLAST and Pfam support.
#
# Input:
#   - longest_orfs.pep
#   - longest_orfs.cds
#   - both_supported.ids (base IDs, e.g. TRINITY_DN0_c2_g1_i1)
#
# Output (in $OUTDIR):
#   - both_supported.proteins.pep
#   - both_supported.cds
#   - extraction_summary.txt
#
# Notes:
#   - seqtk subseq is used (fast, memory-light).
#   - IDs are expanded to include all isoforms (.p1, .p2, etc.).
# ------------------------------

module purge
module load seqtk/1.4-GCC-13.3.0

# Input files
PEP="/scratch/eeg37520/Sept2025_Trinity/9.22.25_TranscriptAssembly_downstream/clean_transcriptome_assembly.fasta.transdecoder_dir/longest_orfs.pep"
CDS="/scratch/eeg37520/Sept2025_Trinity/9.22.25_TranscriptAssembly_downstream/clean_transcriptome_assembly.fasta.transdecoder_dir/longest_orfs.cds"
IDS="/scratch/eeg37520/transdecoder_homology/high_conf_debug/both_supported.ids"

# Output directory
OUTDIR="/scratch/eeg37520/transdecoder_homology/high_conf_debug"
mkdir -p "$OUTDIR"

echo "=== Starting extraction at $(date) ==="
echo "Input PEP: $PEP"
echo "Input CDS: $CDS"
echo "Input IDs: $IDS"
echo "Output dir: $OUTDIR"
echo

# --------------------------------------
# Step 1. Expand base IDs to include .pN isoform suffixes
# Example:
#   TRINITY_DN0_c2_g1_i1  ->  TRINITY_DN0_c2_g1_i1.p1, .p2, ...
# --------------------------------------
echo "Expanding base IDs to isoform IDs..."
grep '^>' "$PEP" | sed 's/^>//' > "$OUTDIR/all_headers.txt"

grep -Ff "$IDS" "$OUTDIR/all_headers.txt" > "$OUTDIR/both_supported.expanded.ids"

echo "  Base IDs requested: $(wc -l < "$IDS")"
echo "  Expanded IDs found in FASTA: $(wc -l < "$OUTDIR/both_supported.expanded.ids")"
echo

# --------------------------------------
# Step 2. Extract sequences with seqtk subseq
# --------------------------------------
echo "Extracting protein sequences..."
seqtk subseq "$PEP" "$OUTDIR/both_supported.expanded.ids" > "$OUTDIR/both_supported.proteins.pep"

echo "Extracting CDS sequences..."
seqtk subseq "$CDS" "$OUTDIR/both_supported.expanded.ids" > "$OUTDIR/both_supported.cds"

# --------------------------------------
# Step 3. Summarize results
# --------------------------------------
pep_count=$(grep -c '^>' "$OUTDIR/both_supported.proteins.pep")
cds_count=$(grep -c '^>' "$OUTDIR/both_supported.cds")

{
  echo "Extraction summary ($(date))"
  echo "---------------------------------"
  echo "Base IDs requested:      $(wc -l < "$IDS")"
  echo "Expanded IDs matched:    $(wc -l < "$OUTDIR/both_supported.expanded.ids")"
  echo "Protein sequences written: $pep_count"
  echo "CDS sequences written:     $cds_count"
} > "$OUTDIR/extraction_summary.txt"

echo "=== Finished at $(date) ==="
echo "Summary written to $OUTDIR/extraction_summary.txt"
