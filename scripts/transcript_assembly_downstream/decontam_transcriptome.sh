#!/bin/bash
#SBATCH --job-name=clean_transcriptome
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=04:00:00
#SBATCH --output=clean_transcriptome_%j.out
#SBATCH --error=clean_transcriptome_%j.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=eeg37520@uga.edu

###############################################################################
# Slurm script to remove contaminant contigs from a transcriptome assembly
# using Kraken2 classification + exact-match taxids.
#
# You must have:
#  1) Kraken2 output file (tab-delimited, e.g. kraken_full.out)
#  2) Contaminant taxid list (one per line, e.g. contam_taxids.txt)
#  3) Original assembly FASTA (whole_transcripts.fasta)
#  4) 'seqkit' installed/loaded (module load seqkit or conda activate)
#
# Output:
#   contaminant_ids.txt       – IDs of contigs classified to contaminants
#   contaminants.fasta        – contaminant contigs (audit file)
#   cleaned_transcripts.fasta – assembly with contaminant contigs removed
#   seq_stats.txt             – stats for both original and cleaned assemblies
###############################################################################

# ---------------------------- USER SETTINGS ----------------------------------
# Paths to your files:
KRAKEN_OUT="/scratch/eeg37520/Sept2025_Trinity/9.22.25_TranscriptAssembly_downstream/kraken_out/4samp_trinity_out_kraken_full_out_classifications.txt"          # Kraken2 output (tab-delimited)
ASSEMBLY="/scratch/eeg37520/Sept2025_Trinity/9.22.25_TranscriptAssembly_downstream/4samp_trinity_out.fasta"    # Original transcriptome
CONTAM_TAXIDS="/scratch/eeg37520/Sept2025_Trinity/9.22.25_TranscriptAssembly_downstream/contam_taxids.txt"     # List of contaminant taxids
# Output file names (will be created in current directory):
CONTAM_IDS="contaminant_ids.txt"
CONTAM_FASTA="contaminants.fasta"
CLEAN_FASTA="cleaned_transcripts.fasta"
SEQ_STATS="seq_stats.txt"
# -----------------------------------------------------------------------------

# Load seqkit if available on your cluster:
module load SeqKit/2.9.0

echo "### Starting contaminant removal pipeline at $(date)"
echo "Kraken2 output:  $KRAKEN_OUT"
echo "Assembly file:   $ASSEMBLY"
echo "Contam taxids:   $CONTAM_TAXIDS"
echo "Output cleaned FASTA: $CLEAN_FASTA"
echo

# Step 3: Extract sequence IDs classified to contaminant taxids (exact match only)
echo "Extracting contaminant contig IDs from Kraken output..."
awk 'NR==FNR{t[$1]=1; next} $1=="C" && ($3 in t){print $2}' \
    "$CONTAM_TAXIDS" "$KRAKEN_OUT" > "$CONTAM_IDS"

N_IDS=$(wc -l < "$CONTAM_IDS")
echo "Found $N_IDS contaminant contig IDs."

# Step 4: Extract contaminant sequences into a separate FASTA for inspection
if [ "$N_IDS" -gt 0 ]; then
    echo "Extracting contaminant contigs..."
    seqkit grep -f "$CONTAM_IDS" "$ASSEMBLY" -o "$CONTAM_FASTA"
else
    echo "No contaminant IDs found. Skipping extraction."
    > "$CONTAM_FASTA"
fi

# Step 5: Create cleaned FASTA by removing contaminant sequences
echo "Creating cleaned assembly (removing contaminants)..."
if [ "$N_IDS" -gt 0 ]; then
    seqkit grep -v -f "$CONTAM_IDS" "$ASSEMBLY" -o "$CLEAN_FASTA"
else
    cp "$ASSEMBLY" "$CLEAN_FASTA"
fi

# Step 6: Generate simple stats for original and cleaned assemblies
echo "Generating stats..."
{
  echo "### Original assembly stats:"
  seqkit stats "$ASSEMBLY"
  echo
  echo "### Contaminants stats:"
  seqkit stats "$CONTAM_FASTA"
  echo
  echo "### Cleaned assembly stats:"
  seqkit stats "$CLEAN_FASTA"
} > "$SEQ_STATS"

echo "Stats written to $SEQ_STATS"
echo "Contaminant IDs:  $CONTAM_IDS"
echo "Contaminants FASTA: $CONTAM_FASTA"
echo "Cleaned FASTA:    $CLEAN_FASTA"
echo "### Pipeline complete at $(date)"
